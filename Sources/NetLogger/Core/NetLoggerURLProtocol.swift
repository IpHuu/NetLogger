import Foundation

final class NetLoggerURLProtocol: URLProtocol {
    static let handledKey = "NetLoggerHandled"
    private var internalSession: URLSession?
    private var internalTask: URLSessionDataTask?
    private var responseData = Data()
    private var startTime: Date?
    private var logId = UUID()

    override class func canInit(with request: URLRequest) -> Bool {
        guard NetLogger.shared.isEnabled else { return false }
        return URLProtocol.property(forKey: handledKey, in: request) == nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            return
        }
        URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutableRequest)

        startTime = Date()
        logId = UUID()

        // 1. Tạo & Ghi log Pending vào Realm
        let log = NetworkLog(
            id: logId,
            timestamp: startTime!,
            method: request.httpMethod ?? "GET",
            url: request.url?.absoluteString ?? "",
            requestHeaders: request.allHTTPHeaderFields ?? [:],
            requestBody: request.httpBody.flatMap { String(data: $0, encoding: .utf8) }
        )

        Task { @MainActor in
            NetLoggerDI.shared.addLogUseCase.execute(log)
        }

        // 2. Kích hoạt request thực
        let config = URLSessionConfiguration.default
        internalSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        internalTask = internalSession?.dataTask(with: mutableRequest as URLRequest)
        internalTask?.resume()
    }

    override func stopLoading() {
        internalTask?.cancel()
        internalSession?.invalidateAndCancel()
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
        responseData.append(data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let duration = startTime.map { Date().timeIntervalSince($0) }
        let httpResponse = task.response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode

        // 3. Cập nhật trạng thái HTTP Response về Realm (chạy background thread)
        Task { @MainActor in
            NetLoggerDI.shared.updateLogUseCase.execute(
                id: logId,
                statusCode: statusCode,
                responseHeaders: httpResponse?.allHeaderFields as? [String: String],
                responseBody: String(data: responseData, encoding: .utf8),
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
