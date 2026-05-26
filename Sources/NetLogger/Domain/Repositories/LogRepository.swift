import Foundation
import Combine

public protocol LogRepository {
    var logsPublisher: AnyPublisher<[NetworkLog], Never> { get }
    var logs: [NetworkLog] { get }
    
    func addLog(_ log: NetworkLog)
    func updateLog(id: UUID, statusCode: Int?, responseHeaders: [String: String]?,
                   responseBody: String?, duration: TimeInterval?, error: String?)
    func clearAll()
    func deleteOldLogs(olderThanDays days: Int)
}
