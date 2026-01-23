//
//  AMPrivateImageView.swift
//  AMFlamingo
//
//  Created by meotech on 2026/1/23.
//

import UIKit

public class AMPrivateImageView: UIView {
    
    // 内部实际显示的图片视图
    private let imageView = UIImageView()
    
    // 借用 UITextField 的安全层
    private let textField: UITextField = {
        let tf = UITextField()
        tf.isSecureTextEntry = true // 开启隐私保护
        return tf
    }()
    
    // 获取安全容器视图
    private var containerView: UIView? {
        // 关键点：在 iOS 系统中，安全层通常是这个私有层
        return textField.subviews.first(where: { type(of: $0).description().contains("CanvasView") })
    }

    public var image: UIImage? {
        get { imageView.image }
        set { imageView.image = newValue }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        // 1. 将 textField 添加到视图中
        addSubview(textField)
        textField.isUserInteractionEnabled = false // 禁用交互，防止弹出键盘
        
        // 2. 将 imageView 添加到 textField 的安全层中
        // 只有这样，截屏时系统才会隐藏图片
        if let secureContainer = containerView {
            secureContainer.addSubview(imageView)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            
            // 3. 设置布局约束
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: self.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
            ])
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        textField.frame = self.bounds
    }
}
