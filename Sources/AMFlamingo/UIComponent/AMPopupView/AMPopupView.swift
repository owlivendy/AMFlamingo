import UIKit

// MARK: - 枚举定义

/// 弹窗展示样式
public enum AMPopupPresentationStyle {
    case fromBottom // 从底部弹出
    case alert      // 居中弹出 (Alert样式)
}

/// 关闭按钮样式
public enum AMPopupCloseButtonStyle {
    case x      // 关闭的样式
    case back   // 返回的样式
    case none   // 没有关闭按钮
}

/// 弹窗 Modal 类型
public enum AMPopupModalType {
    case none   // 不使用modal
    case fullScreen // 全屏modal
    case fullScreenWithoutSafeAreaTop // 不包含上面的安全区域，包含下面的安全区域
}

// MARK: - AMPopupView
public class AMPopupView: UIView {
    /// 背景视图（可自定义背景图片等）
    public var bgView: UIView?
    /// 弹窗 Modal 类型，决定弹窗覆盖范围
    public var modalType: AMPopupModalType = .none
    /// 弹窗展示样式（底部弹出/居中弹出）
    public var presentationStyle: AMPopupPresentationStyle = .fromBottom
    /// 关闭按钮样式（x/返回/无）
    public var closeButtonStyle: AMPopupCloseButtonStyle = .x
    /// 是否启用键盘弹起时的弹窗自动调整
    public var enableKeyboardAdjustment: Bool = true
    /// 键盘与输入框的最小间距
    public var minGapBetweenKeyboardAndTextField: CGFloat = 80
    /// 点击背景是否隐藏弹窗
    public var tapBackgroundToHide: Bool = true

    // 私有属性
    /// 弹窗顶部导航栏（只读）, 如果 presentationStyle 为 .alert，则不显示
    public private(set) var navigationBar: UIView!
    /// 弹窗标题 Label（只读）, 如果 presentationStyle 为 .alert，则不显示
    public private(set) var titleLabel: UILabel!
    /// 弹窗背景视图（只读）, 如果 presentationStyle 为 .alert，则不显示
    private var closeButton: UIButton!
    private var bottomConstraint: NSLayoutConstraint?
    private var centerConstraint: NSLayoutConstraint?
    private weak var maskAlphaView: UIView?
    private var closeButtonLeadingConstraint: NSLayoutConstraint?
    private var closeButtonTrailingConstraint: NSLayoutConstraint?
    private var contentView: UIView?

    private var title: String?

    // MARK: - 初始化方法
    /// 初始化方法, 如果 presentationStyle 为 .alert，则不显示标题和关闭按钮
    /// - Parameters:
    ///   - title: 弹窗标题, 如果 presentationStyle 为 .alert，则不显示
    ///   - customView: 自定义内容视图
    ///   - presentationStyle: 弹窗展示样式（底部弹出/居中弹出）
    public init(title: String? = nil, customView: UIView, presentationStyle: AMPopupPresentationStyle = .fromBottom) {
        super.init(frame: .zero)
        self.backgroundColor = .white
        self.presentationStyle = presentationStyle
        self.enableKeyboardAdjustment = true
        self.minGapBetweenKeyboardAndTextField = 80
        self.title = title
        self.contentView = customView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        removeKeyboardObservers()
    }
    
    private func hasTextFieldOrTextView(in view: UIView) -> Bool {
        if view is UITextField || contentView is UITextView { return true }
        for sub in view.subviews {
            if hasTextFieldOrTextView(in: sub) {
                return true
            }
        }
        return false
    }
    
    // MARK: - 键盘监听
    private func addKeyboardObservers() {
        guard enableKeyboardAdjustment else { return }
        guard let view = contentView else { return }
        guard hasTextFieldOrTextView(in: view) else { return }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func findFirstResponder(in view: UIView) -> UIView? {
        if view.isFirstResponder { return view }
        for sub in view.subviews {
            if let found = findFirstResponder(in: sub) { return found }
        }
        return nil
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard enableKeyboardAdjustment else { return }
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
        guard let contentView = self.contentView else { return }
        
        guard let firstResponder = findFirstResponder(in: contentView) else {
            return
        }
        
        if presentationStyle == .fromBottom {
            let responderFrame = firstResponder.convert(firstResponder.bounds, to: window)
            let responderBottomY = responderFrame.maxY
            let keyboardTopY = window.bounds.height - keyboardFrame.height
            let gap = keyboardTopY - responderBottomY
            if gap < minGapBetweenKeyboardAndTextField {
                let offset = minGapBetweenKeyboardAndTextField - gap
                bottomConstraint?.constant = -offset
                UIView.animate(withDuration: duration) { self.superview?.layoutIfNeeded() }
            }
        } else if presentationStyle == .alert {
            let responderFrame = firstResponder.convert(firstResponder.bounds, to: window)
            let responderBottomY = responderFrame.maxY
            let keyboardTopY = window.bounds.height - keyboardFrame.height
            let gap = keyboardTopY - responderBottomY
            if gap < minGapBetweenKeyboardAndTextField {
                let offset = minGapBetweenKeyboardAndTextField - gap
                centerConstraint?.constant = -offset
                UIView.animate(withDuration: duration) { self.superview?.layoutIfNeeded() }
            }
        }
    }
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard enableKeyboardAdjustment else { return }
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        UIView.animate(withDuration: duration) {
            self.bottomConstraint?.constant = 0
            self.centerConstraint?.constant = 0
            self.superview?.layoutIfNeeded()
        }
    }

    // MARK: - 显示/隐藏
    /// 在指定容器视图中显示弹窗（如不传则自动选择 keyWindow）
    /// - Parameter container: 容器视图
    public func showInView(_ container: UIView?) {
        if let superview = self.superview {
            superview.removeFromSuperview()
        }
        
        if (self.presentationStyle == .alert) {
            self.setupPresentationStyleAlert()
        } else {
            self.setupPresentationStyleFromBottom()
        }
        
        let container = container ?? UIApplication.am_keyWindow
        guard let container = container else { return }
        let maskAlphaView = UIView(frame: container.bounds)
        maskAlphaView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        maskAlphaView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapOnBackground)))
        container.addSubview(maskAlphaView)
        maskAlphaView.addSubview(self)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.maskAlphaView = maskAlphaView
        addKeyboardObservers()
        if let bgView = self.bgView, bgView.superview == nil {
            bgView.translatesAutoresizingMaskIntoConstraints = false
            self.insertSubview(bgView, at: 0)
            NSLayoutConstraint.activate([
                bgView.topAnchor.constraint(equalTo: self.topAnchor),
                bgView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                bgView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                bgView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
            ])
        }
        let screenHeight = UIScreen.main.bounds.height
        if presentationStyle == .fromBottom {
            if modalType == .fullScreen {
                self.layer.cornerRadius = 0
                self.heightAnchor.constraint(equalToConstant: screenHeight).isActive = true
            } else if modalType == .fullScreenWithoutSafeAreaTop {
                var topSafeArea: CGFloat = 0
                if #available(iOS 11.0, *) {
                    topSafeArea = container.safeAreaInsets.top
                }
                self.heightAnchor.constraint(equalToConstant: screenHeight - topSafeArea).isActive = true
            }
            let leading = self.leadingAnchor.constraint(equalTo: container.leadingAnchor)
            let trailing = self.trailingAnchor.constraint(equalTo: container.trailingAnchor)
            let bottom = self.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 0)
            NSLayoutConstraint.activate([leading, trailing, bottom])
            self.bottomConstraint = bottom
            self.transform = CGAffineTransform(translationX: 0, y: screenHeight)
            self.maskAlphaView?.backgroundColor = UIColor.black.withAlphaComponent(0.0)
            UIView.animate(withDuration: 0.2) {
                self.transform = .identity
                self.maskAlphaView?.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            }
        } else if presentationStyle == .alert {
            titleLabel?.isHidden = true
            closeButton?.isHidden = true
            let centerY = self.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            NSLayoutConstraint.activate([
                self.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                centerY,
                self.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 20),
                self.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -20)
            ])
            self.centerConstraint = centerY
            self.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
            self.alpha = 0
            self.maskAlphaView?.backgroundColor = UIColor.black.withAlphaComponent(0.0)
            UIView.animate(withDuration: 0.2) {
                self.alpha = 1
                self.transform = .identity
                self.maskAlphaView?.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            }
        }
    }

    /// 显示弹窗（自动选择 keyWindow）
    public func show() {
        showInView(nil)
    }
    
    @objc func tapOnBackground() {
        guard tapBackgroundToHide else { return }
        self.hide()
    }

    /// 隐藏弹窗
    @objc public func hide() {
        self.endEditing(true)
        removeKeyboardObservers()
        
        if let maskAlphaView = self.maskAlphaView {
            if presentationStyle == .fromBottom {
                UIView.animate(withDuration: 0.2, animations: {
                    self.transform = CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height)
                    maskAlphaView.backgroundColor = UIColor.black.withAlphaComponent(0)
                }, completion: { _ in
                    maskAlphaView.removeFromSuperview()
                    self.removeFromSuperview()
                })
            } else if presentationStyle == .alert {
                UIView.animate(withDuration: 0.2, animations: {
                    self.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
                    self.alpha = 0
                    maskAlphaView.backgroundColor = UIColor.black.withAlphaComponent(0)
                }, completion: { _ in
                    maskAlphaView.removeFromSuperview()
                    self.removeFromSuperview()
                })
            }
        }
    }
} 

private extension AMPopupView {
    
    // MARK: - 关闭按钮样式
    private func updateCloseButtonStyle() {
        // 移除旧约束
        closeButtonLeadingConstraint?.isActive = false
        closeButtonTrailingConstraint?.isActive = false
        switch closeButtonStyle {
        case .x:
            closeButton.setImage(UIImage.am_Image(named: "popupview_close"), for: .normal)
            closeButtonTrailingConstraint?.isActive = true
            closeButton.isHidden = false
        case .back:
            closeButton.setImage(UIImage.am_Image(named: "popupview_back"), for: .normal)
            closeButtonLeadingConstraint?.isActive = true
            closeButton.isHidden = false
        case .none:
            closeButton.isHidden = true
        }
    }

    // MARK: - 弹窗样式
    private func setupPresentationStyleFromBottom() {
        guard let customView = self.contentView else { return }
        self.layer.cornerRadius = 20
        if #available(iOS 11.0, *) {
            self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }

        // 创建标题栏
        let navigationBar = UIView()
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(navigationBar)
        self.navigationBar = navigationBar

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.addSubview(titleLabel)
        self.titleLabel = titleLabel

        let closeBtn = UIButton(type: .custom)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.setImage(UIImage.am_Image(named: "popupview_close"), for: .normal)
        closeBtn.addTarget(self, action: #selector(hide), for: .touchUpInside)
        navigationBar.addSubview(closeBtn)
        self.closeButton = closeBtn

        customView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(customView)
        self.contentView = customView

        // navigationBar 约束
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                navigationBar.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 0),
                navigationBar.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                navigationBar.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                navigationBar.heightAnchor.constraint(equalToConstant: 44)
            ])
        } else {
            NSLayoutConstraint.activate([
                navigationBar.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
                navigationBar.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                navigationBar.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                navigationBar.heightAnchor.constraint(equalToConstant: 44)
            ])
        }

        // closeButton 约束（初始为靠右）
        closeButtonTrailingConstraint = closeBtn.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor, constant: -6)
        closeButtonLeadingConstraint = closeBtn.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor, constant: 6)
        closeButtonTrailingConstraint?.isActive = true
        NSLayoutConstraint.activate([
            closeBtn.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            closeBtn.widthAnchor.constraint(equalToConstant: 44),
            closeBtn.heightAnchor.constraint(equalToConstant: 44)
        ])

        // titleLabel 约束
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: navigationBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
        ])

        // contentView 约束
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                customView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
                customView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                customView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                customView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
                customView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                customView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
            ])
        }
        // contentView 底部约束，兼容 safeArea
        if #available(iOS 11.0, *) {
            customView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            customView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        }
        
        updateCloseButtonStyle()
    }

    // MARK: - 弹窗样式
    private func setupPresentationStyleAlert() {
        guard let customView = self.contentView else { return }
        self.layer.cornerRadius = 20
        if #available(iOS 11.0, *) {
            self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }

        customView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(customView)
        NSLayoutConstraint.activate([
            customView.topAnchor.constraint(equalTo: self.topAnchor),
            customView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            customView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            customView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
}
