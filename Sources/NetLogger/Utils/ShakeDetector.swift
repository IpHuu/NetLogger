import UIKit

final class ShakeDetector {
    static let shared = ShakeDetector()
    private var isEnabled = false

    private init() {}

    func enable() {
        guard !isEnabled else { return }
        isEnabled = true
        swizzleWindow()
    }

    private func swizzleWindow() {
        let klass = UIWindow.self
        let originalSelector = #selector(UIWindow.motionEnded(_:with:))
        let swizzledSelector = #selector(UIWindow.netLogger_motionEnded(_:with:))

        guard let originalMethod = class_getInstanceMethod(klass, originalSelector),
              let swizzledMethod = class_getInstanceMethod(klass, swizzledSelector) else {
            return
        }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

extension UIWindow {
    @objc func netLogger_motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        // Gọi lại hàm gốc (đã swizzled)
        self.netLogger_motionEnded(motion, with: event)

        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShakeNotification, object: nil)
        }
    }
}

extension Notification.Name {
    static let deviceDidShakeNotification = Notification.Name("tech.vinsmartfuture.netlogger.shake")
}
