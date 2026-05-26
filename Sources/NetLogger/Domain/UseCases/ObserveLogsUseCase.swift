import Foundation
import Combine

public struct ObserveLogsUseCase {
    private let repository: LogRepository
    
    public init(repository: LogRepository) {
        self.repository = repository
    }
    
    public func execute() -> AnyPublisher<[NetworkLog], Never> {
        repository.logsPublisher
    }
}
