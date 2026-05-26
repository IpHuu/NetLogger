import Foundation
import Combine

@MainActor
public final class LogListViewModel: ObservableObject {
    @Published public var logs: [NetworkLog] = []
    @Published public var searchText = ""
    @Published public var selectedMethod = "ALL"
    @Published public var selectedStatus = "ALL"
    
    public let methods = ["ALL", "GET", "POST", "PUT", "DELETE"]
    public let statuses = ["ALL", "SUCCESS", "REDIRECT", "CLIENT ERROR", "SERVER ERROR", "PENDING"]
    
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
    
    public var filteredLogs: [NetworkLog] {
        logs.filter { log in
            // Search text filter
            let matchesSearch = searchText.isEmpty || 
                log.url.localizedCaseInsensitiveContains(searchText) || 
                log.method.localizedCaseInsensitiveContains(searchText)
            
            // Method filter
            let matchesMethod = selectedMethod == "ALL" || log.method.uppercased() == selectedMethod
            
            // Status filter
            let matchesStatus: Bool
            if selectedStatus == "ALL" {
                matchesStatus = true
            } else {
                guard let code = log.statusCode else {
                    matchesStatus = selectedStatus == "PENDING"
                    return matchesSearch && matchesMethod && matchesStatus
                }
                switch selectedStatus {
                case "SUCCESS":
                    matchesStatus = (200...299).contains(code)
                case "REDIRECT":
                    matchesStatus = (300...399).contains(code)
                case "CLIENT ERROR":
                    matchesStatus = (400...499).contains(code)
                case "SERVER ERROR":
                    matchesStatus = (500...599).contains(code)
                default:
                    matchesStatus = false
                }
            }
            
            return matchesSearch && matchesMethod && matchesStatus
        }
    }
}
