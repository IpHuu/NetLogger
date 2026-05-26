import Foundation
import RealmSwift

@MainActor
public final class LogRealmManager: ObservableObject {
    public static let shared = LogRealmManager()

    @Published public private(set) var logs: [NetworkLog] = []

    private var notificationToken: NotificationToken?
    private let backgroundQueue = DispatchQueue(label: "tech.vinsmartfuture.netlogger.realm", qos: .background)

    private init() {
        setupRealm()
        observeLogs()
    }

    private func setupRealm() {
        // Lưu trữ vào .cachesDirectory để tránh bị backup iCloud và dễ dàng dọn dẹp
        var config = Realm.Configuration.defaultConfiguration
        config.fileURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("netlogger_realm.realm")
        config.schemaVersion = 1
        config.migrationBlock = { migration, oldSchemaVersion in
            // Xử lý di chuyển schema nếu có nâng cấp sau này
        }
        Realm.Configuration.defaultConfiguration = config
    }

    private func observeLogs() {
        do {
            let realm = try Realm()
            let results = realm.objects(NetworkLogObject.self).sorted(byKeyPath: "timestamp", ascending: false)
            
            notificationToken = results.observe { [weak self] changes in
                guard let self = self else { return }
                switch changes {
                case .initial(let collection), .update(let collection, _, _, _):
                    // Map sang Pure Struct để đảm bảo Thread-Safety và hiển thị UI
                    self.logs = collection.map { NetworkLog(from: $0) }
                case .error(let error):
                    print("NetLogger Realm: Lỗi giám sát biến động database: \(error)")
                }
            }
        } catch {
            print("NetLogger Realm: Lỗi khởi tạo Realm instance: \(error)")
        }
    }

    deinit {
        notificationToken?.invalidate()
    }

    // MARK: - CRUD API

    public func addLog(_ log: NetworkLog) {
        backgroundQueue.async {
            do {
                let realm = try Realm()
                let object = NetworkLogObject()
                object.id = log.id
                object.timestamp = log.timestamp
                object.method = log.method
                object.url = log.url
                
                let reqHeadersData = (try? JSONEncoder().encode(log.requestHeaders)) ?? Data()
                object.requestHeadersJson = String(data: reqHeadersData, encoding: .utf8) ?? "{}"
                object.requestBody = log.requestBody
                object.statusCode = nil

                try realm.write {
                    realm.add(object, update: .modified)
                }
            } catch {
                print("NetLogger Realm: Không thể lưu log mới: \(error)")
            }
        }
    }

    public func updateLog(
        id: UUID,
        statusCode: Int?,
        responseHeaders: [String: String]?,
        responseBody: String?,
        duration: TimeInterval?,
        error: String?
    ) {
        backgroundQueue.async {
            do {
                let realm = try Realm()
                guard let object = realm.object(ofType: NetworkLogObject.self, forPrimaryKey: id) else { return }

                try realm.write {
                    if let statusCode = statusCode {
                        object.statusCode = statusCode
                    }
                    if let responseHeaders = responseHeaders {
                        let respHeadersData = (try? JSONEncoder().encode(responseHeaders)) ?? Data()
                        object.responseHeadersJson = String(data: respHeadersData, encoding: .utf8)
                    }
                    if let responseBody = responseBody {
                        object.responseBody = responseBody
                    }
                    if let duration = duration {
                        object.duration = duration
                    }
                    if let error = error {
                        object.errorDescription = error
                    }
                }
            } catch {
                print("NetLogger Realm: Không thể cập nhật kết quả log: \(error)")
            }
        }
    }

    public func clearAll() {
        backgroundQueue.async {
            do {
                let realm = try Realm()
                let objects = realm.objects(NetworkLogObject.self)
                try realm.write {
                    realm.delete(objects)
                }
            } catch {
                print("NetLogger Realm: Lỗi xóa toàn bộ database: \(error)")
            }
        }
    }

    public func deleteOldLogs(olderThanDays days: Int) {
        backgroundQueue.async {
            do {
                let realm = try Realm()
                let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
                let oldObjects = realm.objects(NetworkLogObject.self).filter("timestamp < %@", cutoffDate)
                
                try realm.write {
                    realm.delete(oldObjects)
                }
            } catch {
                print("NetLogger Realm: Lỗi dọn dẹp logs cũ: \(error)")
            }
        }
    }
}
