//
//  AMNavigationBar.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/8/13.
//  Copyright © 2025 shen xiaofei. All rights reserved.
//

import UIKit

/// 自定义导航栏视图，支持返回按钮、标题和右侧视图的配置
class AMNavigationBar: UIView {
    
    // MARK: - Properties
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    
    /// 导航栏标题文本，设置后会显示在中间位置
    var title: String? {
        didSet {
            titleLabel.text = title
            titleLabel.isHidden = title == nil || customTitleView != nil
            if customTitleView == nil {
                updateTitleConstraints()
            }
        }
    }
    
    var titleColor: UIColor? {
        didSet {
            applyTintColor()
        }
    }
    
    /// 自定义标题视图，可以替换默认的文本标题
    /// 注意：设置后会替换默认的文本标题并居中显示
    var customTitleView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            titleLabel.isHidden = customTitleView != nil
            if let customTitleView = customTitleView {
                addSubview(customTitleView)
                setupCustomTitleViewConstraints(customTitleView)
            } else {
                // When custom title view is removed, update title label constraints
                updateTitleConstraints()
            }
        }
    }
    
    /// 导航栏主题色调，影响返回按钮和标题颜色
    override var tintColor: UIColor? {
        didSet {
            applyTintColor()
        }
    }
    
    /// 返回按钮点击回调
    /// 如果设置了此回调，将使用自定义处理逻辑；否则使用默认的返回逻辑
    var onBackButtonTapped: (() -> Void)?
    
    // MARK: - Initialization
    
    /// 使用指定的 frame 初始化导航栏
    /// - Parameter frame: 导航栏的 frame
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    /// 使用 Storyboard/XIB 初始化导航栏
    /// - Parameter coder: NSCoder 对象
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .white
        
        // Add all views to main view
        addSubview(backButton)
        addSubview(titleLabel)
        
        // Setup back button
        backButton.setImage(UIImage(named: "back-icon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        backButton.setContentHuggingPriority(.required, for: .horizontal)
        backButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // Setup title label
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        
        // Apply initial tintColor
        applyTintColor()
        
        // Setup constraints
        setupConstraints()
    }
    
    private func applyTintColor() {
        if let tintcolor = tintColor {
            backButton.tintColor = tintcolor
        } else {
            backButton.tintColor = .black
        }
        if let newColor = titleColor {
            titleLabel.textColor = newColor
        } else {
            titleLabel.textColor = tintColor
        }
        
    }
    
    // MARK: - Private Methods
    private func setupConstraints() {
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Back button constraints
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            backButton.topAnchor.constraint(equalTo: self.topAnchor),
            backButton.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        updateTitleConstraints()
    }
    
    private func updateTitleConstraints() {
        guard customTitleView == nil else { return }
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Remove existing constraints that we manage
//        NSLayoutConstraint.deactivate(titleLabel.constraints.filter { constraint in
//            return constraint.firstItem === titleLabel && 
//                   (constraint.firstAttribute == .centerX || 
//                    constraint.firstAttribute == .trailing || 
//                    constraint.firstAttribute == .leading)
//        })
        
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
    
    private func setupCustomTitleViewConstraints(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // Remove existing constraints that we manage
        NSLayoutConstraint.deactivate(view.constraints.filter { constraint in
            return constraint.firstItem === view && 
                   (constraint.firstAttribute == .centerX || 
                    constraint.firstAttribute == .centerY || 
                    constraint.firstAttribute == .leading || 
                    constraint.firstAttribute == .trailing)
        })
        
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: centerXAnchor),
            view.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        if let customHandler = onBackButtonTapped {
            customHandler()
        } else {
            handleDefaultBackAction()
        }
    }
    
    private func handleDefaultBackAction() {
        // Find the view controller that contains this navigation bar
        if let viewController = findViewController() {
            if let navigationController = viewController.navigationController {
                // If there's more than one view controller in the stack, pop
                if navigationController.viewControllers.count > 1 {
                    navigationController.popViewController(animated: true)
                } else {
                    // If this is the root view controller, dismiss if presented modally
                    viewController.dismiss(animated: true)
                }
            } else {
                // No navigation controller, try to dismiss if presented modally
                viewController.dismiss(animated: true)
            }
        }
    }
    
    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}
