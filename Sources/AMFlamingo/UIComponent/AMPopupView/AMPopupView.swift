import UIKit

// MARK: - 枚举定义

/// 弹窗展示样式
public enum AMPopupPresentationStyle {
    case fromBottom // 从底部弹出
    case alert      // 居中弹出 (Alert 样式)
}

/// 导航栏按钮样式
public enum AMPopupNavigationBarStyle {
    case x               // 右侧关闭
    case back            // 左侧返回
    case cancelAndSure   // 左侧取消 + 右侧确定
}

/// 弹窗 Modal 类型（仅 `fromBottom` 时生效）
public enum AMPopupModalType {
    case none
    case threeOverFourScreen
    case fullScreen
    case fullScreenWithoutSafeAreaTop
    case fullScreenWithoutNavigationBar
}

// MARK: - AMPopupView

/// Swift 版弹窗组件，对齐 `CHPopupView` 能力。
public class AMPopupView: UIView {

    private static let contentTopConstant: CGFloat = 54
    private static let animationDuration: TimeInterval = 0.4
    private static let navigationBarHeight: CGFloat = 44

    // MARK: Public Properties

    /// 背景图（在 `show` 前设置，展示时插入最底层）
    public var bgView: UIView?

    /// 内容视图
    public private(set) var contentView: UIView!

    /// 标题 Label（仅 `fromBottom` 样式，Alert 时为 `nil`）
    public private(set) var titleLabel: UILabel?

    /// Modal 类型，决定弹窗高度；`none` 时由 `contentView` 约束决定高度
    public var modalType: AMPopupModalType = .none

    /// 弹出样式（初始化后只读）
    public private(set) var presentationStyle: AMPopupPresentationStyle

    /// 导航栏样式，默认 `.x`
    public var navigationBarStyle: AMPopupNavigationBarStyle = .x {
        didSet { applyNavigationBarStyle() }
    }

    /// 导航栏左侧自定义视图（设置后隐藏默认左侧按钮）
    public var navigationLeftItemView: UIView? {
        didSet { updateNavigationLeftItemView(oldValue: oldValue) }
    }

    /// 右侧按钮点击回调；设置后需自行处理关闭逻辑
    public var rightButtonPressed: ((AMPopupView) -> Void)?

    /// 点击遮罩是否关闭，默认 `true`（仅 `fromBottom` 生效）
    public var hiddenWhenTappedMask: Bool = true

    /// 是否隐藏导航栏，默认 `false`
    public var hiddenNavigationBar: Bool = false {
        didSet {
            contentTopConstraint?.constant = hiddenNavigationBar ? 0 : Self.contentTopConstant
        }
    }

    /// 弹窗关闭后的回调（X/返回/遮罩/代码 `hide()` 等）
    public var onDismiss: ((AMPopupView) -> Void)?

    /// 是否启用键盘避让
    public var enableKeyboardAdjustment: Bool = true

    /// 键盘与输入框的最小间距，默认 80
    public var minGapBetweenKeyboardAndTextField: CGFloat = 80

    /// 左侧按钮点击拦截，返回 `false` 时不执行默认关闭
    public var shouldExecLeftButtonTaped: ((AMPopupView) -> Bool)?

    /// 右侧按钮点击拦截，返回 `false` 时不执行默认关闭；与 `rightButtonPressed` 同时设置时仅执行 `rightButtonPressed`
    public var shouldExecRightButtonTaped: ((AMPopupView) -> Bool)?

    // MARK: Private Properties

    private var navigationView: UIView!
    private var leftButton: UIButton!
    private var rightButton: UIButton!
    private var contentTopConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var centerYConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?
    private weak var maskAlphaView: UIView?

    // MARK: - Init

    /// 从底部弹出的初始化方法（带标题栏）
    public convenience init(title: String, customView: UIView) {
        self.init(title: title, customView: customView, presentationStyle: .fromBottom)
    }

    /// Alert 样式的初始化方法（无标题栏）
    public convenience init(alertCustomView customView: UIView) {
        self.init(title: nil, customView: customView, presentationStyle: .alert)
    }

    public init(title: String?, customView: UIView, presentationStyle: AMPopupPresentationStyle = .fromBottom) {
        self.presentationStyle = presentationStyle
        super.init(frame: .zero)
        backgroundColor = .white
        layer.cornerRadius = 20
        clipsToBounds = true
        enableKeyboardAdjustment = true
        minGapBetweenKeyboardAndTextField = 80
        hiddenWhenTappedMask = true

        switch presentationStyle {
        case .fromBottom:
            setupFromBottom(title: title ?? "", customView: customView)
        case .alert:
            setupAlert(customView: customView)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        removeKeyboardObservers()
    }

    // MARK: - Show / Hide

    public func show() {
        showWithCompletion(nil)
    }

    public func showWithCompletion(_ completion: (() -> Void)?) {
        showInView(nil, completion: completion)
    }

    public func showInView(_ container: UIView?) {
        showInView(container, completion: nil)
    }

    public func showInView(_ container: UIView?, completion: (() -> Void)?) {
        if let superview {
            superview.removeFromSuperview()
        }

        let container = container ?? UIApplication.am_keyWindow
        guard let container else { return }

        let mask = UIControl(frame: container.bounds)
        mask.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        mask.addTarget(self, action: #selector(maskTapped), for: .touchUpInside)
        container.addSubview(mask)
        mask.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        maskAlphaView = mask

        addKeyboardObservers()
        installBackgroundViewIfNeeded()

        let screenHeight = UIScreen.main.bounds.height

        if presentationStyle == .fromBottom {
            applyModalHeight(screenHeight: screenHeight, container: container)

            let leading = leadingAnchor.constraint(equalTo: mask.leadingAnchor)
            let trailing = trailingAnchor.constraint(equalTo: mask.trailingAnchor)
            let bottom = bottomAnchor.constraint(equalTo: mask.bottomAnchor)
            NSLayoutConstraint.activate([leading, trailing, bottom])
            bottomConstraint = bottom

            transform = CGAffineTransform(translationX: 0, y: screenHeight)
            mask.backgroundColor = UIColor.black.withAlphaComponent(0)
            UIView.animate(withDuration: Self.animationDuration, animations: {
                self.transform = .identity
                mask.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            }, completion: { _ in completion?() })
        } else {
            navigationView?.isHidden = true
            titleLabel?.isHidden = true
            leftButton?.isHidden = true
            rightButton?.isHidden = true
            navigationLeftItemView?.isHidden = true

            let centerY = centerYAnchor.constraint(equalTo: mask.centerYAnchor)
            NSLayoutConstraint.activate([
                centerXAnchor.constraint(equalTo: mask.centerXAnchor),
                centerY,
                leadingAnchor.constraint(greaterThanOrEqualTo: mask.leadingAnchor, constant: 20),
                trailingAnchor.constraint(lessThanOrEqualTo: mask.trailingAnchor, constant: -20),
            ])
            centerYConstraint = centerY

            transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
            alpha = 0
            mask.backgroundColor = UIColor.black.withAlphaComponent(0)
            UIView.animate(withDuration: Self.animationDuration, animations: {
                self.alpha = 1
                self.transform = .identity
                mask.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            }, completion: { _ in completion?() })
        }
    }

    @objc public func hide() {
        endEditing(true)
        removeKeyboardObservers()

        guard let maskAlphaView else { return }
        let screenHeight = UIScreen.main.bounds.height

        if presentationStyle == .fromBottom {
            UIView.animate(withDuration: Self.animationDuration, animations: {
                self.transform = CGAffineTransform(translationX: 0, y: screenHeight)
                maskAlphaView.backgroundColor = UIColor.black.withAlphaComponent(0)
            }, completion: { _ in
                self.onDismiss?(self)
                maskAlphaView.removeFromSuperview()
                self.removeFromSuperview()
            })
        } else {
            UIView.animate(withDuration: Self.animationDuration, animations: {
                self.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
                self.alpha = 0
                maskAlphaView.backgroundColor = UIColor.black.withAlphaComponent(0)
            }, completion: { _ in
                self.onDismiss?(self)
                maskAlphaView.removeFromSuperview()
                self.removeFromSuperview()
            })
        }
    }
}

// MARK: - Setup

private extension AMPopupView {

    func setupFromBottom(title: String, customView: UIView) {
        if #available(iOS 11.0, *) {
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }

        let navigationView = UIView()
        navigationView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(navigationView)
        self.navigationView = navigationView

        let titleLabel = UILabel(frame: .zero)
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        navigationView.addSubview(titleLabel)
        self.titleLabel = titleLabel

        let leftButton = UIButton(type: .custom)
        leftButton.titleLabel?.font = .systemFont(ofSize: 15)
        leftButton.isHidden = true
        leftButton.translatesAutoresizingMaskIntoConstraints = false
        leftButton.addTarget(self, action: #selector(leftButtonTapped), for: .touchUpInside)
        navigationView.addSubview(leftButton)
        self.leftButton = leftButton

        let rightButton = UIButton(type: .custom)
        rightButton.titleLabel?.font = .systemFont(ofSize: 15)
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.addTarget(self, action: #selector(rightButtonTapped), for: .touchUpInside)
        navigationView.addSubview(rightButton)
        self.rightButton = rightButton

        customView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(customView)
        contentView = customView

        NSLayoutConstraint.activate([
            navigationView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            navigationView.leadingAnchor.constraint(equalTo: leadingAnchor),
            navigationView.trailingAnchor.constraint(equalTo: trailingAnchor),
            navigationView.heightAnchor.constraint(equalToConstant: Self.navigationBarHeight),

            leftButton.topAnchor.constraint(equalTo: navigationView.topAnchor),
            leftButton.leadingAnchor.constraint(equalTo: navigationView.leadingAnchor, constant: 10),
            leftButton.widthAnchor.constraint(equalToConstant: 44),
            leftButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerYAnchor.constraint(equalTo: navigationView.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: navigationView.centerXAnchor),

            rightButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            rightButton.trailingAnchor.constraint(equalTo: navigationView.trailingAnchor, constant: -15),
            rightButton.widthAnchor.constraint(equalToConstant: 44),
            rightButton.heightAnchor.constraint(equalToConstant: 44),

            customView.topAnchor.constraint(equalTo: navigationView.bottomAnchor, constant: 10),
            customView.leadingAnchor.constraint(equalTo: leadingAnchor),
            customView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        let contentTop = customView.topAnchor.constraint(
            equalTo: safeAreaLayoutGuide.topAnchor,
            constant: Self.contentTopConstant
        )
        contentTop.isActive = true
        contentTopConstraint = contentTop

        if let window = UIApplication.am_keyWindow, window.safeAreaInsets.bottom > 0 {
            customView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -window.safeAreaInsets.bottom).isActive = true
        } else {
            customView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        }

        applyNavigationBarStyle()
    }

    func setupAlert(customView: UIView) {
        if #available(iOS 11.0, *) {
            layer.maskedCorners = [
                .layerMinXMinYCorner, .layerMaxXMinYCorner,
                .layerMinXMaxYCorner, .layerMaxXMaxYCorner,
            ]
        }

        customView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(customView)
        contentView = customView

        NSLayoutConstraint.activate([
            customView.topAnchor.constraint(equalTo: topAnchor),
            customView.leadingAnchor.constraint(equalTo: leadingAnchor),
            customView.trailingAnchor.constraint(equalTo: trailingAnchor),
            customView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func applyModalHeight(screenHeight: CGFloat, container: UIView) {
        heightConstraint?.isActive = false
        switch modalType {
        case .none:
            heightConstraint = nil
        case .threeOverFourScreen:
            layer.cornerRadius = 20
            heightConstraint = heightAnchor.constraint(equalToConstant: screenHeight * 0.75)
        case .fullScreen:
            layer.cornerRadius = 0
            heightConstraint = heightAnchor.constraint(equalToConstant: screenHeight)
        case .fullScreenWithoutSafeAreaTop:
            layer.cornerRadius = 20
            let topSafeArea = container.safeAreaInsets.top
            heightConstraint = heightAnchor.constraint(equalToConstant: screenHeight - topSafeArea)
        case .fullScreenWithoutNavigationBar:
            layer.cornerRadius = 20
            let topSpace = container.safeAreaInsets.top + Self.navigationBarHeight
            heightConstraint = heightAnchor.constraint(equalToConstant: screenHeight - topSpace)
        }
        heightConstraint?.isActive = true
    }

    func installBackgroundViewIfNeeded() {
        guard let bgView, bgView.superview == nil else { return }
        bgView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(bgView, at: 0)
        NSLayoutConstraint.activate([
            bgView.topAnchor.constraint(equalTo: topAnchor),
            bgView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func applyNavigationBarStyle() {
        guard leftButton != nil, rightButton != nil else { return }

        switch navigationBarStyle {
        case .x:
            leftButton.isHidden = true
            rightButton.isHidden = false
            leftButton.setImage(nil, for: .normal)
            leftButton.setTitle(nil, for: .normal)
            rightButton.setImage(UIImage.am_Image(named: "popupview_close"), for: .normal)
            rightButton.setTitle(nil, for: .normal)
            rightButton.setTitleColor(nil, for: .normal)
        case .back:
            leftButton.isHidden = false
            rightButton.isHidden = true
            leftButton.setImage(UIImage.am_Image(named: "popupview_back"), for: .normal)
            leftButton.setTitle(nil, for: .normal)
            rightButton.setImage(nil, for: .normal)
            rightButton.setTitle(nil, for: .normal)
        case .cancelAndSure:
            leftButton.isHidden = false
            rightButton.isHidden = false
            leftButton.setImage(nil, for: .normal)
            leftButton.setTitle("取消", for: .normal)
            leftButton.setTitleColor(.am_themeBlue, for: .normal)
            rightButton.setImage(nil, for: .normal)
            rightButton.setTitle("确定", for: .normal)
            rightButton.setTitleColor(.am_themeBlue, for: .normal)
        }

        if navigationLeftItemView != nil {
            leftButton.isHidden = true
        }
    }

    func updateNavigationLeftItemView(oldValue: UIView?) {
        oldValue?.removeFromSuperview()
        guard let navigationView else { return }

        if let itemView = navigationLeftItemView {
            itemView.translatesAutoresizingMaskIntoConstraints = false
            navigationView.addSubview(itemView)
            NSLayoutConstraint.activate([
                itemView.topAnchor.constraint(equalTo: navigationView.topAnchor),
                itemView.leadingAnchor.constraint(equalTo: navigationView.leadingAnchor, constant: 10),
                itemView.heightAnchor.constraint(equalToConstant: Self.navigationBarHeight),
            ])
            leftButton.isHidden = true
        } else {
            applyNavigationBarStyle()
        }
    }
}

// MARK: - Actions

private extension AMPopupView {

    @objc func maskTapped() {
        guard presentationStyle == .fromBottom, hiddenWhenTappedMask else { return }
        hide()
    }

    @objc func leftButtonTapped() {
        var shouldExec = true
        if let shouldExecLeftButtonTaped {
            shouldExec = shouldExecLeftButtonTaped(self)
        }
        if shouldExec {
            hide()
        }
    }

    @objc func rightButtonTapped() {
        if let rightButtonPressed {
            rightButtonPressed(self)
            return
        }

        var shouldExec = true
        if let shouldExecRightButtonTaped {
            shouldExec = shouldExecRightButtonTaped(self)
        }
        if shouldExec {
            hide()
        }
    }
}

// MARK: - Keyboard

private extension AMPopupView {

    func hasTextFieldOrTextView(in view: UIView) -> Bool {
        if view is UITextField || view is UITextView { return true }
        for sub in view.subviews where hasTextFieldOrTextView(in: sub) {
            return true
        }
        return false
    }

    func findFirstResponder(in view: UIView) -> UIView? {
        if view.isFirstResponder { return view }
        for sub in view.subviews {
            if let found = findFirstResponder(in: sub) { return found }
        }
        return nil
    }

    func addKeyboardObservers() {
        guard enableKeyboardAdjustment, hasTextFieldOrTextView(in: contentView) else { return }
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
    }

    func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        guard enableKeyboardAdjustment,
              let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let window = UIApplication.am_keyWindow,
              let firstResponder = findFirstResponder(in: contentView) else { return }

        let responderFrame = firstResponder.convert(firstResponder.bounds, to: window)
        let gap = (window.bounds.height - keyboardFrame.height) - responderFrame.maxY
        guard gap < minGapBetweenKeyboardAndTextField else { return }

        let offset = minGapBetweenKeyboardAndTextField - gap
        if presentationStyle == .fromBottom, let bottomConstraint {
            bottomConstraint.constant = -offset
        } else if presentationStyle == .alert, let centerYConstraint {
            centerYConstraint.constant = -offset
        }
        UIView.animate(withDuration: duration) { self.superview?.layoutIfNeeded() }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        guard enableKeyboardAdjustment,
              let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }

        if presentationStyle == .fromBottom {
            guard bottomConstraint?.constant != 0 else { return }
            bottomConstraint?.constant = 0
        } else if presentationStyle == .alert {
            guard centerYConstraint?.constant != 0 else { return }
            centerYConstraint?.constant = 0
        }
        UIView.animate(withDuration: duration) { self.superview?.layoutIfNeeded() }
    }
}
