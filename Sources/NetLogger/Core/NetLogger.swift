import UIKit
import SwiftUI

@MainActor
public final class NetLogger {
    public static let shared = NetLogger()

    public private(set) var isEnabled = false
    public var config = NetLoggerConfig()

    private init() {}

    public func start() {
        #if DEBUG
        guard !isEnabled else { return }
        isEnabled = true
        URLProtocol.registerClass(NetLoggerURLProtocol.self)
        swizzleURLSessionConfiguration()
        
        if config.enableShake {
            ShakeDetector.shared.enable()
            NotificationCenter.default.addObserver(self, selector: #selector(deviceDidShake), name: .deviceDidShakeNotification, object: nil)
        }
        
        if config.enableFloatingButton {
            FloatingButtonWindow.shared.show()
        }
        
        // Tự động xoá logs cũ
        LogRealmManager.shared.deleteOldLogs(olderThanDays: config.autoDeleteDays)
        #endif
    }

    public func stop() {
        isEnabled = false
        URLProtocol.unregisterClass(NetLoggerURLProtocol.self)
        FloatingButtonWindow.shared.hide()
        NotificationCenter.default.removeObserver(self, name: .deviceDidShakeNotification, object: nil)
    }

    @objc private func deviceDidShake() {
        show()
    }

    public func makeView() -> some View {
        LogListView()
    }

    public func makeViewController() -> UIViewController {
        UIHostingController(rootView: makeView())
    }

    public func show() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        
        var topController = root
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        // Tránh present đè nếu đã mở rồi
        if topController is UIHostingController<LogListView> {
            return
        }
        
        let vc = makeViewController()
        vc.modalPresentationStyle = .pageSheet
        topController.present(vc, animated: true)
    }

    private func swizzleURLSessionConfiguration() {
        let klass = URLSessionConfiguration.self
        let originalMethod = class_getClassMethod(klass, #selector(getter: klass.default))
        let swizzledMethod = class_getClassMethod(klass, #selector(getter: klass.netLogger_default))
        
        if let original = originalMethod, let swizzled = swizzledMethod {
            method_exchangeImplementations(original, swizzled)
        }
    }

    // MARK: - Manual Logging
    
    public enum LogLevel: String, Sendable {
        case debug = "DEBUG"
        case info = "INFO"
        case error = "ERROR"
    }

    public func log(_ message: String, tag: String = "General", level: LogLevel = .info) {
        let log = NetworkLog(
            id: UUID(),
            timestamp: Date(),
            method: level.rawValue,
            url: "[\(tag.uppercased())] \(message)",
            requestHeaders: [:],
            requestBody: nil,
            statusCode: level == .error ? 500 : 200,
            responseHeaders: [:],
            responseBody: nil,
            errorDescription: level == .error ? message : nil,
            duration: nil
        )
        
        LogRealmManager.shared.addLog(log)
    }
}

// Swizzle Helper
extension URLSessionConfiguration {
    @objc class var netLogger_default: URLSessionConfiguration {
        let config = self.netLogger_default
        if NetLogger.shared.isEnabled {
            var protocols = config.protocolClasses ?? []
            if !protocols.contains(where: { $0 == NetLoggerURLProtocol.self }) {
                protocols.insert(NetLoggerURLProtocol.self, at: 0)
                config.protocolClasses = protocols
            }
        }
        return config
    }
}
