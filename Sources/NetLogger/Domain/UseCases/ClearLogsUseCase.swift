import Foundation

public struct ClearLogsUseCase {
    private let repository: LogRepository
    
    public init(repository: LogRepository) {
        self.repository = repository
    }
    
    public func execute() {
        repository.clearAll()
    }
}
