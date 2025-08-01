import UIKit
import AMFlamingo

class AMPopupDemoController: UIViewController, UITextFieldDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "AMPopupView 演示"
        view.backgroundColor = .systemBackground
        
        let showButton = UIButton(type: .system)
        showButton.setTitle("底部弹出 AMPopupView", for: .normal)
        showButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        showButton.addTarget(self, action: #selector(showPopup), for: .touchUpInside)
        showButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(showButton)
        
        let showAlertButton = UIButton(type: .system)
        showAlertButton.setTitle("Alert 弹出 AMPopupView", for: .normal)
        showAlertButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        showAlertButton.addTarget(self, action: #selector(showAlertPopup), for: .touchUpInside)
        showAlertButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(showAlertButton)
        
        NSLayoutConstraint.activate([
            showButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            showButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            showButton.heightAnchor.constraint(equalToConstant: 48),
            showButton.widthAnchor.constraint(equalToConstant: 200),
            
            showAlertButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            showAlertButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 40),
            showAlertButton.heightAnchor.constraint(equalToConstant: 48),
            showAlertButton.widthAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    @objc private func showPopup() {
        let customView = UILabel()
        customView.isUserInteractionEnabled = true
        customView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapOnCustomView(sender:))))
        customView.text = "这是自定义内容"
        customView.textAlignment = .center
        customView.font = .systemFont(ofSize: 16)
        customView.backgroundColor = .systemGray6
        customView.layer.cornerRadius = 8
        customView.clipsToBounds = true
        customView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            customView.heightAnchor.constraint(equalToConstant: 280),
//            customView.widthAnchor.constraint(equalToConstant: 220)
//        ])
        
        let popup = AMPopupView(title: "弹窗标题", customView: customView, presentationStyle: .fromBottom)
        popup.tapBackgroundToHide = true
        popup.closeButtonStyle = .x
        popup.modalType = .fullScreenWithoutSafeAreaTop
        popup.show()
    }
    
    @objc private func showAlertPopup() {
        let containerView = UIView()
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 12
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "登录"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        let usernameField = UITextField()
        usernameField.placeholder = "请输入用户名"
        usernameField.borderStyle = .roundedRect
        usernameField.font = .systemFont(ofSize: 16)
        usernameField.delegate = self
        usernameField.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(usernameField)
        
        let passwordField = UITextField()
        passwordField.placeholder = "请输入密码"
        passwordField.borderStyle = .roundedRect
        passwordField.font = .systemFont(ofSize: 16)
        passwordField.isSecureTextEntry = true
        passwordField.delegate = self
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(passwordField)
        
        let loginButton = UIButton(type: .system)
        loginButton.setTitle("登录", for: .normal)
        loginButton.backgroundColor = .systemBlue
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 8
        loginButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(loginButton)
        
        NSLayoutConstraint.activate([
            containerView.widthAnchor.constraint(equalToConstant: 280),
            containerView.heightAnchor.constraint(equalToConstant: 400),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 216),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            titleLabel.heightAnchor.constraint(equalToConstant: 24),
            
            usernameField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            usernameField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            usernameField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            usernameField.heightAnchor.constraint(equalToConstant: 44),
            
            passwordField.topAnchor.constraint(equalTo: usernameField.bottomAnchor, constant: 12),
            passwordField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            passwordField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            passwordField.heightAnchor.constraint(equalToConstant: 44),
            
            loginButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 16),
            loginButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            loginButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            loginButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        let popup = AMPopupView(title: nil, customView: containerView, presentationStyle: .alert)
        popup.enableKeyboardAdjustment = true
        popup.minGapBetweenKeyboardAndTextField = 20
        popup.tapBackgroundToHide = true
        popup.show()
    }
    
    @objc func tapOnCustomView(sender: UITapGestureRecognizer) {
        print("tapOnCustomView")
        
        showAlertPopup()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
