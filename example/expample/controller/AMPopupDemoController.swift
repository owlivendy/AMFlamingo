import UIKit
import AMFlamingo

class AMPopupDemoController: AMBaseController, UITextFieldDelegate {

    private let stackView = UIStackView()
    
    private weak var popup: AMPopupView?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "AMPopupView 演示"
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
