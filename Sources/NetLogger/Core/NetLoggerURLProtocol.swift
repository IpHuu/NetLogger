import Foundation

final class NetLoggerURLProtocol: URLProtocol, @unchecked Sendable {
    static let handledKey = "NetLoggerHandled"
    private let lock = NSLock()
    private var internalSession: URLSession?
    private var internalTask: URLSessionDataTask?
    private var responseData = Data()
    private var startTime: Date?
    private var logId = UUID()

    override class func canInit(with request: URLRequest) -> Bool {
        guard globalNetLoggerState.isEnabled else { return false }
        return URLProtocol.property(forKey: handledKey, in: request) == nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    private func extractBody(from request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }
        
        stream.open()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        var data = Data()
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        buffer.deallocate()
        stream.close()
        return data.isEmpty ? nil : data
    }

    override func startLoading() {
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            return
        }
        URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutableRequest)

        let bodyData = extractBody(from: request)
        if bodyData != nil {
            mutableRequest.httpBody = bodyData
            // URLProtocol sometimes drops the stream, so we convert it to data
        }

        let newStartTime = Date()
        let newLogId = UUID()

        lock.withLock {
            startTime = newStartTime
            logId = newLogId
        }

        let log = NetworkLog(
            id: newLogId,
            timestamp: newStartTime,
            method: request.httpMethod ?? "GET",
            url: request.url?.absoluteString ?? "",
            requestHeaders: request.allHTTPHeaderFields ?? [:],
            requestBody: bodyData.flatMap { String(data: $0, encoding: .utf8) }
        )

        Task { @MainActor in
            NetLoggerDI.shared.addLogUseCase.execute(log)
        }

        // 2. Kích hoạt request thực
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: mutableRequest as URLRequest)
        
        lock.withLock {
            internalSession = session
            internalTask = task
        }
        task.resume()
    }

    override func stopLoading() {
        lock.withLock {
            internalTask?.cancel()
            internalSession?.invalidateAndCancel()
        }
    }
}

// MARK: - URLSessionDataDelegate
extension NetLoggerURLProtocol: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)
        lock.withLock {
            responseData.append(data)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let (duration, currentLogId, currentResponseData) = lock.withLock { () -> (TimeInterval?, UUID, Data) in
            let d = startTime.map { Date().timeIntervalSince($0) }
            return (d, logId, responseData)
        }
        
        let httpResponse = task.response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode

        Task { @MainActor in
            NetLoggerDI.shared.updateLogUseCase.execute(
                id: currentLogId,
                statusCode: statusCode,
                responseHeaders: httpResponse?.allHeaderFields as? [String: String],
                responseBody: String(data: currentResponseData, encoding: .utf8),
                duration: duration,
                error: error?.localizedDescription
            )
        }

        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
    }
}
