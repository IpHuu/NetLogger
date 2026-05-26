import Foundation

struct NetworkLogMapper {
    static func toDomain(_ object: NetworkLogObject) -> NetworkLog {
        let requestHeaders = (try? JSONDecoder().decode([String: String].self, from: Data(object.requestHeadersJson.utf8))) ?? [:]
        let responseHeaders = object.responseHeadersJson.flatMap {
            try? JSONDecoder().decode([String: String].self, from: Data($0.utf8))
        }
        
        return NetworkLog(
            id: object.id,
            timestamp: object.timestamp,
            method: object.method,
            url: object.url,
            requestHeaders: requestHeaders,
            requestBody: object.requestBody,
            statusCode: object.statusCode,
            responseHeaders: responseHeaders,
            responseBody: object.responseBody,
            errorDescription: object.errorDescription,
            duration: object.duration
        )
    }
    
    static func toRealm(_ log: NetworkLog) -> NetworkLogObject {
        let object = NetworkLogObject()
        object.id = log.id
        object.timestamp = log.timestamp
        object.method = log.method
        object.url = log.url
        
        if let requestHeadersData = try? JSONEncoder().encode(log.requestHeaders),
           let jsonString = String(data: requestHeadersData, encoding: .utf8) {
            object.requestHeadersJson = jsonString
        } else {
            object.requestHeadersJson = "{}"
        }
        
        object.requestBody = log.requestBody
        object.statusCode = log.statusCode
        
        if let responseHeaders = log.responseHeaders,
           let responseHeadersData = try? JSONEncoder().encode(responseHeaders) {
            object.responseHeadersJson = String(data: responseHeadersData, encoding: .utf8)
        } else {
            object.responseHeadersJson = nil
        }
        
        object.responseBody = log.responseBody
        object.errorDescription = log.errorDescription
        object.duration = log.duration
        
        return object
    }
}
