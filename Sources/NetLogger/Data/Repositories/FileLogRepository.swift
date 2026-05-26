import Foundation
import Combine

public final class FileLogRepository: LogRepository, @unchecked Sendable {
    @Published public private(set) var logs: [NetworkLog] = []
    
    private let queue = DispatchQueue(label: "com.vtrip.netlogger.fileRepository", qos: .background)
    private let fileURL: URL
    public var maxEntries: Int
    
    public var logsPublisher: AnyPublisher<[NetworkLog], Never> {
        $logs.eraseToAnyPublisher()
    }
    
    public init(maxEntries: Int = 1000) {
        self.maxEntries = maxEntries
        
        // Setup file URL in Caches directory
        let cachePaths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDir = cachePaths[0]
        self.fileURL = cacheDir.appendingPathComponent("netlogger_logs.json")
        
        loadFromFile()
    }
    
    public func addLog(_ log: NetworkLog) {
        queue.async { [weak self] in
            guard let self = self else { return }
            var currentLogs = self.logs
            currentLogs.insert(log, at: 0) // Newest first
            
            // Trim if needed
            if currentLogs.count > self.maxEntries {
                currentLogs = Array(currentLogs.prefix(self.maxEntries))
            }
            
            self.updateAndSave(currentLogs)
        }
    }
    
    public func updateLog(id: UUID, statusCode: Int?, responseHeaders: [String: String]?, responseBody: String?, duration: TimeInterval?, error: String?) {
        queue.async { [weak self] in
            guard let self = self else { return }
            var currentLogs = self.logs
            if let index = currentLogs.firstIndex(where: { $0.id == id }) {
                var updated = currentLogs[index]
                if let statusCode = statusCode { updated.statusCode = statusCode }
                if let responseHeaders = responseHeaders { updated.responseHeaders = responseHeaders }
                if let responseBody = responseBody { updated.responseBody = responseBody }
                if let duration = duration { updated.duration = duration }
                if let error = error { updated.errorDescription = error }
                currentLogs[index] = updated
                self.updateAndSave(currentLogs)
            }
        }
    }
    
    public func clearAll() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.updateAndSave([])
        }
    }
    
    public func deleteOldLogs(olderThanDays days: Int) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            let filteredLogs = self.logs.filter { $0.timestamp >= cutoffDate }
            
            if filteredLogs.count != self.logs.count {
                self.updateAndSave(filteredLogs)
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func updateAndSave(_ newLogs: [NetworkLog]) {
        // Update published property on main thread
        DispatchQueue.main.async {
            self.logs = newLogs
        }
        
        // Save to file on background queue
        do {
            let data = try JSONEncoder().encode(newLogs)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[NetLogger] Failed to save logs to file: \(error)")
        }
    }
    
    private func loadFromFile() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decodedLogs = try JSONDecoder().decode([NetworkLog].self, from: data)
            DispatchQueue.main.async {
                self.logs = decodedLogs
            }
        } catch {
            print("[NetLogger] Failed to load logs from file: \(error)")
        }
    }
}
