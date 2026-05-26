import UIKit
import SwiftUI

public extension UIViewController {
    func presentNetLogger() {
        NetLogger.shared.show()
    }
}
