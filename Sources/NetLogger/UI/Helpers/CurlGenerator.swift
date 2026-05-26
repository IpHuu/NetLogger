import Foundation

public struct CurlGenerator {
    public static func generate(from log: NetworkLog) -> String {
        var components = ["curl -i"]
        
        components.append("-X \(log.method)")
        
        // Add Request Headers
        for (key, value) in log.requestHeaders {
            let escapedKey = key.replacingOccurrences(of: "\"", with: "\\\"")
            let escapedValue = value.replacingOccurrences(of: "\"", with: "\\\"")
            components.append("-H \"\(escapedKey): \(escapedValue)\"")
        }
        
        // Add Request Body
        if let body = log.requestBody, !body.isEmpty {
            let escapedBody = body.replacingOccurrences(of: "\"", with: "\\\"")
                                  .replacingOccurrences(of: "\n", with: "")
            components.append("-d \"\(escapedBody)\"")
        }
        
        components.append("\"\(log.url)\"")
        
        return components.joined(separator: " \\\n  ")
    }
}
