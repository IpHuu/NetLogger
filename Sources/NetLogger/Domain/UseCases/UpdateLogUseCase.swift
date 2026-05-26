import Foundation

public struct UpdateLogUseCase {
    private let repository: LogRepository
    
    public init(repository: LogRepository) {
        self.repository = repository
    }
    
    public func execute(
        id: UUID,
        statusCode: Int?,
        responseHeaders: [String: String]?,
        responseBody: String?,
        duration: TimeInterval?,
        error: String?
    ) {
        repository.updateLog(
            id: id,
            statusCode: statusCode,
            responseHeaders: responseHeaders,
            responseBody: responseBody,
            duration: duration,
            error: error
        )
    }
}
