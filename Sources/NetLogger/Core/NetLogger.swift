import UIKit
import SwiftUI

internal final class NetLoggerState: @unchecked Sendable {
    private let lock = NSLock()
    private var _isEnabled = false
    
    var isEnabled: Bool {
        get { lock.withLock { _isEnabled } }
        set { lock.withLock { _isEnabled = newValue } }
    }
}

internal let globalNetLoggerState = NetLoggerState()

@MainActor
public final class NetLogger {
    public static let shared = NetLogger()

    public var isEnabled: Bool {
        globalNetLoggerState.isEnabled
    }
    public var config = NetLoggerConfig()

    private init() {}

    public func start() {
        guard !globalNetLoggerState.isEnabled else { return }
        globalNetLoggerState.isEnabled = true
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
        NetLoggerDI.shared.deleteOldLogsUseCase.execute(olderThanDays: config.autoDeleteDays)
    }

    public func stop() {
        globalNetLoggerState.isEnabled = false
        URLProtocol.unregisterClass(NetLoggerURLProtocol.self)
        FloatingButtonWindow.shared.hide()
        NotificationCenter.default.removeObserver(self, name: .deviceDidShakeNotification, object: nil)
    }

    @objc private func deviceDidShake() {
        show()
    }

    public func makeView() -> some View {
        LogListView(viewModel: NetLoggerDI.shared.makeLogListViewModel())
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
        
        // Swizzle default
        let originalDefault = class_getClassMethod(klass, #selector(getter: klass.default))
        let swizzledDefault = class_getClassMethod(klass, #selector(getter: klass.netLogger_default))
        if let original = originalDefault, let swizzled = swizzledDefault {
            method_exchangeImplementations(original, swizzled)
        }
        
        // Swizzle ephemeral
        let originalEphemeral = class_getClassMethod(klass, #selector(getter: klass.ephemeral))
        let swizzledEphemeral = class_getClassMethod(klass, #selector(getter: klass.netLogger_ephemeral))
        if let original = originalEphemeral, let swizzled = swizzledEphemeral {
            method_exchangeImplementations(original, swizzled)
        }
    }

    // MARK: - Manual Logging
    
    public enum LogLevel: String, Sendable {
        case debug = "DEBUG"
        case info = "INFO"
        case warn = "WARN"
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
        
        NetLoggerDI.shared.addLogUseCase.execute(log)
    }

    // MARK: - Public APIs for custom networking clients
    
    @discardableResult
    public func logRequest(id: UUID = UUID(), method: String, url: String, headers: [String: String] = [:], body: String? = nil) -> UUID {
        let log = NetworkLog(
            id: id,
            timestamp: Date(),
            method: method,
            url: url,
            requestHeaders: headers,
            requestBody: body
        )
        NetLoggerDI.shared.addLogUseCase.execute(log)
        return id
    }
    
    public func logResponse(id: UUID, statusCode: Int?, responseHeaders: [String: String]? = nil, responseBody: String? = nil, duration: TimeInterval? = nil, error: String? = nil) {
        NetLoggerDI.shared.updateLogUseCase.execute(
            id: id,
            statusCode: statusCode,
            responseHeaders: responseHeaders,
            responseBody: responseBody,
            duration: duration,
            error: error
        )
    }
}

// Swizzle Helper
extension URLSessionConfiguration {
    @objc class var netLogger_default: URLSessionConfiguration {
        let config = self.netLogger_default
        if globalNetLoggerState.isEnabled {
            var protocols = config.protocolClasses ?? []
            if !protocols.contains(where: { $0 == NetLoggerURLProtocol.self }) {
                protocols.insert(NetLoggerURLProtocol.self, at: 0)
                config.protocolClasses = protocols
            }
        }
        return config
    }
    
    @objc class var netLogger_ephemeral: URLSessionConfiguration {
        let config = self.netLogger_ephemeral
        if globalNetLoggerState.isEnabled {
            var protocols = config.protocolClasses ?? []
            if !protocols.contains(where: { $0 == NetLoggerURLProtocol.self }) {
                protocols.insert(NetLoggerURLProtocol.self, at: 0)
                config.protocolClasses = protocols
            }
        }
        return config
    }
}
