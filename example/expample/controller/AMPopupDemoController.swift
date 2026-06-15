import UIKit
import AMFlamingo

class AMPopupDemoController: AMBaseController, UITextFieldDelegate {

    private let stackView = UIStackView()

    private weak var popup: AMPopupView?
    private weak var passthroughOverlay: AMPassthroughView?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "AMPopupView & AMPassthroughView 演示"
        view.backgroundColor = .systemBackground
        setupButtons()
    }

    private func setupButtons() {
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
          stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
          stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
          stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
          stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
        ])

        addDemoButton("底部弹窗 · 关闭 (X)", action: #selector(showBottomWithClose))
        addDemoButton("底部弹窗 · 返回", action: #selector(showBottomWithBack))
        addDemoButton("底部弹窗 · 取消/确定", action: #selector(showBottomWithCancelAndSure))
        addDemoButton("底部弹窗 · 3/4 屏", action: #selector(showBottomThreeQuarter))
        addDemoButton("Alert 弹窗 · 登录表单", action: #selector(showAlertLogin))
        addDemoButton("点击穿透 · AMPassthroughView", action: #selector(showPassthroughOverlay))
    }

    private func addDemoButton(_ title: String, action: Selector) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        stackView.addArrangedSubview(button)
    }

    // MARK: - Demos

    @objc private func showBottomWithClose() {
        let content = makePlaceholderContent(text: "点击遮罩可关闭", height: 220)
        let popup = AMPopupView(title: "关闭样式", customView: content)
        popup.navigationBarStyle = .x
        popup.modalType = .fullScreenWithoutNavigationBar
        popup.hiddenWhenTappedMask = true
        popup.onDismiss = { _ in print("底部弹窗已关闭") }
        popup.show()
    }

    @objc private func showBottomWithBack() {
        let content = makePlaceholderContent(text: "左侧返回按钮", height: 180)
        let popup = AMPopupView(title: "返回样式", customView: content)
        popup.navigationBarStyle = .back
        popup.modalType = .none
        popup.show()
    }

    @objc private func showBottomWithCancelAndSure() {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.text = "编辑内容..."
        textView.backgroundColor = .systemGray6
        textView.layer.cornerRadius = 8
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.heightAnchor.constraint(equalToConstant: 160).isActive = true

        let popup = AMPopupView(title: "取消 / 确定", customView: textView)
        popup.navigationBarStyle = .cancelAndSure
        popup.modalType = .threeOverFourScreen
        popup.shouldExecRightButtonTaped = { pop in
          print("确定，内容：\(textView.text ?? "")")
          return true
        }
        popup.show()
    }

    @objc private func showBottomThreeQuarter() {
        let content = makePlaceholderContent(text: "3/4 屏高度", height: 120)
        let popup = AMPopupView(title: "3/4 Modal", customView: content)
        popup.modalType = .threeOverFourScreen
        popup.show()
    }

    @objc private func showAlertLogin() {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel(frame: .zero)
        titleLabel.text = "登录"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)

        let usernameField = UITextField()
        usernameField.placeholder = "请输入用户名"
        usernameField.borderStyle = .roundedRect
        usernameField.delegate = self
        usernameField.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(usernameField)

        let passwordField = UITextField()
        passwordField.placeholder = "请输入密码"
        passwordField.borderStyle = .roundedRect
        passwordField.isSecureTextEntry = true
        passwordField.delegate = self
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(passwordField)

        let loginButton = UIButton(type: .system)
        loginButton.setTitle("登录", for: .normal)
        loginButton.backgroundColor = .systemBlue
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 8
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.addTarget(self, action: #selector(alertLoginTapped), for: .touchUpInside)
        container.addSubview(loginButton)

        NSLayoutConstraint.activate([
          container.widthAnchor.constraint(equalToConstant: 280),

          titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
          titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
          titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

          usernameField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
          usernameField.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
          usernameField.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
          usernameField.heightAnchor.constraint(equalToConstant: 44),

          passwordField.topAnchor.constraint(equalTo: usernameField.bottomAnchor, constant: 12),
          passwordField.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
          passwordField.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
          passwordField.heightAnchor.constraint(equalToConstant: 44),

          loginButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 16),
          loginButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
          loginButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
          loginButton.heightAnchor.constraint(equalToConstant: 44),
          loginButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
        ])

        let popup = AMPopupView(alertCustomView: container)
        popup.enableKeyboardAdjustment = true
        popup.minGapBetweenKeyboardAndTextField = 20
        popup.onDismiss = { _ in print("Alert 已关闭") }
        popup.show()
        self.popup = popup
    }

    @objc private func alertLoginTapped() {
        view.endEditing(true)
        self.popup?.hide()
    }

    /// 演示 `AMPassthroughView` / `AMUIStackPassthroughView`：全屏半透明遮罩不拦截空白区域点击，下方按钮仍可点；遮罩上的浮动控件可正常响应。
    @objc private func showPassthroughOverlay() {
        if passthroughOverlay != nil {
            removePassthroughOverlay()
            return
        }

        let overlay = AMPassthroughView(frame: view.bounds)
        overlay.allowHitTestPassthrough = true
        overlay.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlay)
        passthroughOverlay = overlay

        let hintLabel = UILabel(frame: .zero)
        hintLabel.text = "空白区域点击会穿透到下方按钮\n上方「关闭穿透层」和右侧标签仍可点击"
        hintLabel.numberOfLines = 0
        hintLabel.font = .systemFont(ofSize: 14)
        hintLabel.textColor = .secondaryLabel
        hintLabel.textAlignment = .center
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(hintLabel)

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("关闭穿透层", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        closeButton.backgroundColor = .systemBlue
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.layer.cornerRadius = 8
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(removePassthroughOverlay), for: .touchUpInside)
        overlay.addSubview(closeButton)

        let stackPassthrough = AMUIStackPassthroughView()
        stackPassthrough.axis = .horizontal
        stackPassthrough.spacing = 8
        stackPassthrough.alignment = .center
        stackPassthrough.allowHitTestPassthrough = true
        stackPassthrough.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(stackPassthrough)

        let tagTitles = ["可点 A", "可点 B", "可点 C"]
        for title in tagTitles {
            let tag = UIButton(type: .system)
            tag.setTitle(title, for: .normal)
            tag.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            tag.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.2)
            tag.layer.cornerRadius = 6
            tag.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
            tag.addAction(UIAction { _ in
                print("AMUIStackPassthroughView 子按钮点击: \(title)")
            }, for: .touchUpInside)
            stackPassthrough.addArrangedSubview(tag)
        }

        NSLayoutConstraint.activate([
            hintLabel.topAnchor.constraint(equalTo: overlay.safeAreaLayoutGuide.topAnchor, constant: 16),
            hintLabel.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 24),
            hintLabel.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -24),

            closeButton.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 16),
            closeButton.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 140),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            stackPassthrough.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -16),
            stackPassthrough.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
        ])
    }

    @objc private func removePassthroughOverlay() {
        passthroughOverlay?.removeFromSuperview()
        passthroughOverlay = nil
    }

    // MARK: - Helpers

    private func makePlaceholderContent(text: String, height: CGFloat) -> UIView {
        let label = UILabel(frame: .zero)
        label.text = text
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16)
        label.backgroundColor = .systemGray6
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.heightAnchor.constraint(equalToConstant: height).isActive = true
        return label
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
