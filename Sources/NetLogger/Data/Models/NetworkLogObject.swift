import Foundation
import RealmSwift

class NetworkLogObject: Object {
    @Persisted(primaryKey: true) var id: UUID
    @Persisted var timestamp: Date = Date()
    @Persisted var method: String = ""
    @Persisted var url: String = ""
    @Persisted var requestHeadersJson: String = "{}"
    @Persisted var requestBody: String? = nil
    
    @Persisted var statusCode: Int? = nil
    @Persisted var responseHeadersJson: String? = nil
    @Persisted var responseBody: String? = nil
    @Persisted var errorDescription: String? = nil
    @Persisted var duration: Double? = nil
}
