import Foundation

public struct NetLoggerConfig {
    public var maxEntries: Int = 1000
    public var autoDeleteDays: Int = 7
    public var enableShake: Bool = true
    public var enableFloatingButton: Bool = false
    public var shakeSensitivity: ShakeSensitivity = .medium

    public enum ShakeSensitivity {
        case low
        case medium
        case high
    }
    
    public init() {}
}
