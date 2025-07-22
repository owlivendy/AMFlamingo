import UIKit

public extension UIApplication {
    /// 获取当前应用的 key window，兼容 iOS 13+
    static var am_keyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .filter { $0.activationState == .foregroundActive }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
                ?? UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first
        } else {
            return UIApplication.shared.keyWindow
        }
    }

    /// 获取当前应用的所有 window，兼容 iOS 13+
    static var am_windows: [UIWindow] {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
        } else {
            return UIApplication.shared.windows
        }
    }

    /// 获取当前应用的主 window，优先返回 key window，如果没有则返回第一个 window
    static var am_mainWindow: UIWindow? {
        return am_keyWindow ?? am_windows.first
    }
} 
