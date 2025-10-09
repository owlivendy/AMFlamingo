import UIKit

final class AMToastWindow: UIWindow {
    static let shared: AMToastWindow = {
        let window = AMToastWindow(frame: UIScreen.main.bounds)
        window.setupWindow()
        return window
    }()
    
    private var toastViewController: AMToastViewController?
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupWindow() {
        windowLevel = AMToastConfig.Window.defaultWindowLevel
        backgroundColor = .clear
        isUserInteractionEnabled = false
        isHidden = true
        
        // 设置 windowScene
        if #available(iOS 13.0, *) {
            updateWindowScene()
        }
        
        toastViewController = AMToastViewController()
        rootViewController = toastViewController
    }
    
    @available(iOS 13.0, *)
    private func updateWindowScene() {
        // 优先使用活跃的场景
        if let activeScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            self.windowScene = activeScene
        }
        // 如果没有活跃场景，使用第一个前台场景
        else if let foregroundScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundInactive }) as? UIWindowScene {
            self.windowScene = foregroundScene
        }
        // 如果都没有，使用第一个可用场景
        else if let firstScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            self.windowScene = firstScene
        }
    }
    
    func addToastViewToQueue(_ toastView: UIView, position: AMToastViewPosition, duration: TimeInterval, delay: TimeInterval) {
        toastViewController?.addToastViewToQueue(toastView, position: position, duration: duration, delay: delay)
    }
    
    func addToastViewToQueue(_ toastView: UIView, position: AMToastViewPosition, duration: TimeInterval) {
        if #available(iOS 13.0, *) {
            updateWindowScene()
        }
        show()
        toastViewController?.addToastViewToQueue(toastView, position: position, duration: duration)
    }
    
    private func show() {
        isHidden = false
    }
    
    func hide() {
        isHidden = true
    }
} 
