import Foundation
import Combine

@MainActor
public final class LogListViewModel: ObservableObject {
    @Published public var logs: [NetworkLog] = []
    @Published public var searchText = ""
    @Published public var selectedChip: LogTypeChip = .all
    
    public enum LogTypeChip: String, CaseIterable {
        case all = "All"
        case api = "API"
        case resource = "Resource"
        case general = "General"
        case error = "Error"
    }
    
    // Will be bound to FiltersAndSettings later
    @Published public var selectedMethods: Set<String> = []
    @Published public var selectedStatusGroups: Set<String> = []
    
    private let observeLogsUseCase: ObserveLogsUseCase
    private var cancellables = Set<AnyCancellable>()
    
    public init(observeLogsUseCase: ObserveLogsUseCase) {
        self.observeLogsUseCase = observeLogsUseCase
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        observeLogsUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] logs in
                self?.logs = logs
            }
            .store(in: &cancellables)
    }
    
    public func clearLogs() {
        NetLoggerDI.shared.clearLogsUseCase.execute()
    }
    
    private func isResourceUrl(_ urlString: String) -> Bool {
        // Strip out query parameters and fragments before getting path extension
        guard let url = URL(string: urlString) else { return false }
        let ext = url.pathExtension.lowercased()
        let resourceExtensions = ["png", "jpg", "jpeg", "gif", "svg", "webp", "ico", "css", "js", "woff", "woff2", "ttf", "eot", "mp4", "mp3", "avif"]
        return resourceExtensions.contains(ext)
    }
    
    private var filteredLogs: [NetworkLog] {
        logs.filter { log in
            // Search text filter
            let matchesSearch = searchText.isEmpty || 
                log.url.localizedCaseInsensitiveContains(searchText) || 
                log.method.localizedCaseInsensitiveContains(searchText)
            
            // Chip filter
            let matchesChip: Bool
            let methodUpper = log.method.uppercased()
            switch selectedChip {
            case .all:
                matchesChip = true
            case .api:
                let apiMethods = ["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS"]
                matchesChip = apiMethods.contains(methodUpper) && !isResourceUrl(log.url)
            case .resource:
                let apiMethods = ["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS"]
                matchesChip = apiMethods.contains(methodUpper) && isResourceUrl(log.url)
            case .general:
                let generalMethods = ["INFO", "DEBUG", "WARN"]
                matchesChip = generalMethods.contains(methodUpper)
            case .error:
                matchesChip = methodUpper == "ERROR" || (log.statusCode ?? 0) >= 400
            }
            
            // Filters from Settings
            let matchesMethod = selectedMethods.isEmpty || selectedMethods.contains(methodUpper)
            
            let matchesStatus: Bool
            if selectedStatusGroups.isEmpty {
                matchesStatus = true
            } else {
                if let code = log.statusCode {
                    let group = "\(code / 100)xx"
                    matchesStatus = selectedStatusGroups.contains(group)
                } else {
                    matchesStatus = false
                }
            }
            
            return matchesSearch && matchesChip && matchesMethod && matchesStatus
        }
    }
    
    public var groupedLogs: [(String, [NetworkLog])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let grouped = Dictionary(grouping: filteredLogs) { log -> String in
            let date = calendar.startOfDay(for: log.timestamp)
            if date == today {
                return "Today"
            } else if date == yesterday {
                return "Yesterday"
            } else {
                return formatter.string(from: date)
            }
        }
        
        // Sort keys (Today first, then Yesterday, then by date descending)
        let sortedKeys = grouped.keys.sorted { key1, key2 in
            if key1 == "Today" { return true }
            if key2 == "Today" { return false }
            if key1 == "Yesterday" { return true }
            if key2 == "Yesterday" { return false }
            return key1 > key2
        }
        
        return sortedKeys.map { ($0, grouped[$0]!) }
    }
}
