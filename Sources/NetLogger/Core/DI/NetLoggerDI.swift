import Foundation

@MainActor
public final class NetLoggerDI {
    public static let shared = NetLoggerDI()
    
    // Data Layer Repository
    public let logRepository: LogRepository
    
    // Domain Use Cases
    public let observeLogsUseCase: ObserveLogsUseCase
    public let addLogUseCase: AddLogUseCase
    public let updateLogUseCase: UpdateLogUseCase
    public let clearLogsUseCase: ClearLogsUseCase
    public let deleteOldLogsUseCase: DeleteOldLogsUseCase
    
    private init() {
        let repo = RealmLogRepository()
        self.logRepository = repo
        
        self.observeLogsUseCase = ObserveLogsUseCase(repository: repo)
        self.addLogUseCase = AddLogUseCase(repository: repo)
        self.updateLogUseCase = UpdateLogUseCase(repository: repo)
        self.clearLogsUseCase = ClearLogsUseCase(repository: repo)
        self.deleteOldLogsUseCase = DeleteOldLogsUseCase(repository: repo)
    }
    
    // Presentation ViewModels Factories
    public func makeLogListViewModel() -> LogListViewModel {
        LogListViewModel(observeLogsUseCase: observeLogsUseCase)
    }
    
    public func makeLogSettingsViewModel() -> LogSettingsViewModel {
        LogSettingsViewModel(
            config: NetLogger.shared.config,
            clearLogsUseCase: clearLogsUseCase,
            onShakeToggled: { enabled in
                if enabled {
                    ShakeDetector.shared.enable()
                }
            },
            onFloatingToggled: { enabled in
                if enabled {
                    FloatingButtonWindow.shared.show()
                } else {
                    FloatingButtonWindow.shared.hide()
                }
            },
            onConfigUpdated: { maxEntries, autoDeleteDays, sensitivity in
                NetLogger.shared.config.maxEntries = maxEntries
                NetLogger.shared.config.autoDeleteDays = autoDeleteDays
                NetLogger.shared.config.shakeSensitivity = sensitivity
            }
        )
    }
}
