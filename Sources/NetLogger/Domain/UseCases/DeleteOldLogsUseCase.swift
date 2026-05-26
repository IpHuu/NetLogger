import Foundation

public struct DeleteOldLogsUseCase {
    private let repository: LogRepository
    
    public init(repository: LogRepository) {
        self.repository = repository
    }
    
    public func execute(olderThanDays days: Int) {
        repository.deleteOldLogs(olderThanDays: days)
    }
}
