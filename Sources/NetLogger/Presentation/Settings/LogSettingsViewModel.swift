import Foundation
import Combine

@MainActor
public final class LogSettingsViewModel: ObservableObject {
    @Published public var maxEntries: Double
    @Published public var autoDeleteDays: Double
    @Published public var enableShake: Bool
    @Published public var enableFloating: Bool
    @Published public var shakeSensitivity: Double
    
    private let clearLogsUseCase: ClearLogsUseCase
    private let onShakeToggled: (Bool) -> Void
    private let onFloatingToggled: (Bool) -> Void
    private let onConfigUpdated: (Int, Int, NetLoggerConfig.ShakeSensitivity) -> Void
    
    public init(
        config: NetLoggerConfig,
        clearLogsUseCase: ClearLogsUseCase,
        onShakeToggled: @escaping (Bool) -> Void,
        onFloatingToggled: @escaping (Bool) -> Void,
        onConfigUpdated: @escaping (Int, Int, NetLoggerConfig.ShakeSensitivity) -> Void
    ) {
        self.maxEntries = Double(config.maxEntries)
        self.autoDeleteDays = Double(config.autoDeleteDays)
        self.enableShake = config.enableShake
        self.enableFloating = config.enableFloatingButton
        self.clearLogsUseCase = clearLogsUseCase
        self.onShakeToggled = onShakeToggled
        self.onFloatingToggled = onFloatingToggled
        self.onConfigUpdated = onConfigUpdated
        
        switch config.shakeSensitivity {
        case .low: self.shakeSensitivity = 0.0
        case .medium: self.shakeSensitivity = 1.0
        case .high: self.shakeSensitivity = 2.0
        }
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
        let sensitivity: NetLoggerConfig.ShakeSensitivity
        if shakeSensitivity < 0.5 { sensitivity = .low }
        else if shakeSensitivity < 1.5 { sensitivity = .medium }
        else { sensitivity = .high }
        
        onConfigUpdated(Int(maxEntries), Int(autoDeleteDays), sensitivity)
    }
}
