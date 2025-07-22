import UIKit
import AMFlamingo

class AMPopupDemoController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "AMPopupView 演示"
        view.backgroundColor = .systemBackground
        
        let showButton = UIButton(type: .system)
        showButton.setTitle("弹出 AMPopupView", for: .normal)
        showButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        showButton.addTarget(self, action: #selector(showPopup), for: .touchUpInside)
        showButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(showButton)
        NSLayoutConstraint.activate([
            showButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            showButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            showButton.heightAnchor.constraint(equalToConstant: 48),
            showButton.widthAnchor.constraint(equalToConstant: 180)
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
        NSLayoutConstraint.activate([
            customView.heightAnchor.constraint(equalToConstant: 280),
            customView.widthAnchor.constraint(equalToConstant: 220)
        ])
        
        let popup = AMPopupView(title: "弹窗标题", customView: customView, presentationStyle: .alert)
        popup.tapBackgroundToHide = true
        popup.show()
    }
    
    @objc func tapOnCustomView(sender: UITapGestureRecognizer) {
        print("tapOnCustomView")
    }
}
