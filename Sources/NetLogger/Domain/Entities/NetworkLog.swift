import Foundation

public struct NetworkLog: Codable, Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date

    // Request
    public let method: String
    public let url: String
    public let requestHeaders: [String: String]
    public let requestBody: String?

    // Response
    public var statusCode: Int?
    public var responseHeaders: [String: String]?
    public var responseBody: String?
    public var errorDescription: String?
    public var duration: TimeInterval? // giây

    public init(
        id: UUID,
        timestamp: Date,
        method: String,
        url: String,
        requestHeaders: [String: String],
        requestBody: String?,
        statusCode: Int? = nil,
        responseHeaders: [String: String]? = nil,
        responseBody: String? = nil,
        errorDescription: String? = nil,
        duration: TimeInterval? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.method = method
        self.url = url
        self.requestHeaders = requestHeaders
        self.requestBody = requestBody
        self.statusCode = statusCode
        self.responseHeaders = responseHeaders
        self.responseBody = responseBody
        self.errorDescription = errorDescription
        self.duration = duration
    }
}
