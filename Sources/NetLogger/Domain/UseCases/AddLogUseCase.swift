import Foundation

public struct AddLogUseCase {
    private let repository: LogRepository
    
    public init(repository: LogRepository) {
        self.repository = repository
    }
    
    public func execute(_ log: NetworkLog) {
        repository.addLog(log)
    }
}
