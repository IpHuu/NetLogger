import UIKit
import SwiftUI

final class FloatingButtonWindow: UIWindow {
    static let shared = FloatingButtonWindow()
    
    private var button: UIButton?
    
    private init() {
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        self.windowScene = scene
        
        let screenBounds = UIScreen.main.bounds
        self.frame = CGRect(x: screenBounds.width - 70, y: screenBounds.height / 2 - 25, width: 50, height: 50)
        self.windowLevel = .statusBar + 100
        self.backgroundColor = .clear
        
        let btn = UIButton(type: .custom)
        btn.frame = self.bounds
        btn.layer.cornerRadius = 25
        btn.backgroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 0.85) // Dark Glassmorphism
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor(white: 1.0, alpha: 0.15).cgColor
        
        // Add subtle shadow
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowOpacity = 0.3
        btn.layer.shadowRadius = 8
        
        // Add magnifying glass / search icon
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let icon = UIImage(systemName: "terminal.fill", withConfiguration: config)
        btn.setImage(icon, for: .normal)
        btn.tintColor = .systemGreen
        
        btn.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        // Pan Gesture for drag & drop
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        btn.addGestureRecognizer(panGesture)
        
        self.addSubview(btn)
        self.button = btn
        self.isHidden = false
    }
    
    func hide() {
        self.isHidden = true
        self.windowScene = nil
    }
    
    @objc private func buttonTapped() {
        NetLogger.shared.show()
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let button = button else { return }
        let translation = gesture.translation(in: self)
        
        var newCenter = CGPoint(x: self.center.x + translation.x, y: self.center.y + translation.y)
        
        // Keep button inside screen bounds
        let screen = UIScreen.main.bounds
        let margin: CGFloat = 30
        newCenter.x = max(margin, min(screen.width - margin, newCenter.x))
        newCenter.y = max(margin, min(screen.height - margin, newCenter.y))
        
        self.center = newCenter
        gesture.setTranslation(.zero, in: self)
        
        // Snap to edge on gesture end
        if gesture.state == .ended {
            let snapX = newCenter.x < screen.width / 2 ? margin + 10 : screen.width - margin - 10
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                self.center = CGPoint(x: snapX, y: newCenter.y)
            }, completion: nil)
        }
    }
}
