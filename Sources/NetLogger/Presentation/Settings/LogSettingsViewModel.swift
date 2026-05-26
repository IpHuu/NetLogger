import Foundation
import Combine

@MainActor
public final class LogSettingsViewModel: ObservableObject {
    @Published public var maxEntries: Double
    @Published public var autoDeleteDays: Double
    @Published public var enableShake: Bool
    @Published public var enableFloating: Bool
    
    private let clearLogsUseCase: ClearLogsUseCase
    private let onShakeToggled: (Bool) -> Void
    private let onFloatingToggled: (Bool) -> Void
    private let onConfigUpdated: (Int, Int) -> Void
    
    public init(
        config: NetLoggerConfig,
        clearLogsUseCase: ClearLogsUseCase,
        onShakeToggled: @escaping (Bool) -> Void,
        onFloatingToggled: @escaping (Bool) -> Void,
        onConfigUpdated: @escaping (Int, Int) -> Void
    ) {
        self.maxEntries = Double(config.maxEntries)
        self.autoDeleteDays = Double(config.autoDeleteDays)
        self.enableShake = config.enableShake
        self.enableFloating = config.enableFloatingButton
        self.clearLogsUseCase = clearLogsUseCase
        self.onShakeToggled = onShakeToggled
        self.onFloatingToggled = onFloatingToggled
        self.onConfigUpdated = onConfigUpdated
    }
    
    public func toggleShake(_ enabled: Bool) {
        enableShake = enabled
        onShakeToggled(enabled)
    }
    
    public func toggleFloating(_ enabled: Bool) {
        enableFloating = enabled
        onFloatingToggled(enabled)
    }
    
    public func updateConfig() {
        onConfigUpdated(Int(maxEntries), Int(autoDeleteDays))
    }
    
    public func clearAllLogs() {
        clearLogsUseCase.execute()
    }
}
