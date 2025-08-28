//
//  AMGradientButton.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/8/22.
//  Copyright © 2025 shen xiaofei. All rights reserved.
//

import UIKit

class AMGradientButton: UIButton {
    // 渐变层
    private let gradientLayer = CAGradientLayer()
    
    // 渐变颜色数组
    var gradientColors: [UIColor] = [] {
        didSet {
            updateGradientLayer()
        }
    }
    
    // 渐变起始点 (默认左中)
    var startPoint: CGPoint = CGPoint(x: 0, y: 0.5) {
        didSet {
            updateGradientLayer()
        }
    }
    
    // 渐变结束点 (默认右中)
    var endPoint: CGPoint = CGPoint(x: 1, y: 0.5) {
        didSet {
            updateGradientLayer()
        }
    }
    
    // 颜色分布位置
    var locations: [NSNumber]? {
        didSet {
            updateGradientLayer()
        }
    }
    
    // 按钮圆角
    var cornerRadius: CGFloat = 8 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    // 初始化方法
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    // 便捷初始化方法，可直接设置渐变属性
    convenience init(colors: [UIColor], startPoint: CGPoint, endPoint: CGPoint) {
        self.init(frame: .zero)
        self.gradientColors = colors
        self.startPoint = startPoint
        self.endPoint = endPoint
        updateGradientLayer()
    }
    
    private func setupButton() {
        // 配置渐变层
        gradientLayer.colors = gradientColors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.locations = locations
        
        // 添加渐变层到按钮层
        layer.insertSublayer(gradientLayer, at: 0)
        
        // 基础样式配置
        setTitleColor(.white, for: .normal)
        titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        layer.cornerRadius = cornerRadius
        clipsToBounds = true
    }
    
    // 更新渐变层属性
    private func updateGradientLayer() {
        gradientLayer.colors = gradientColors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.locations = locations
    }
    
    // 确保渐变层大小与按钮一致
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
    
    // 高亮状态反馈
    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.8 : 1.0
        }
    }
}
