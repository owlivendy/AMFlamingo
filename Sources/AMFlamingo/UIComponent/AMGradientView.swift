//
//  AMGradientView.swift
//  ChinaHomelife247
//
//  Created by meotech on 2025/10/17.
//  Copyright © 2025 吕欢. All rights reserved.
//

import Foundation

open class AMGradientView: UIView {
    // 渐变层
    let gradientLayer = CAGradientLayer()
    
    // 渐变颜色数组
    open var gradientColors: [UIColor] = [] {
        didSet {
            updateGradientLayer()
        }
    }
    
    // 渐变起始点 (默认左中)
    open var startPoint: CGPoint = CGPoint(x: 0, y: 0.5) {
        didSet {
            updateGradientLayer()
        }
    }
    
    // 渐变结束点 (默认右中)
    open var endPoint: CGPoint = CGPoint(x: 1, y: 0.5) {
        didSet {
            updateGradientLayer()
        }
    }
    
    // 颜色分布位置
    open var locations: [NSNumber]? {
        didSet {
            updateGradientLayer()
        }
    }
    
    // 初始化方法
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    // 便捷初始化方法，可直接设置渐变属性
    convenience public init(colors: [UIColor], startPoint: CGPoint, endPoint: CGPoint) {
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
        gradientLayer.masksToBounds = true
        
        // 添加渐变层到按钮层
        layer.insertSublayer(gradientLayer, at: 0)
        
//        clipsToBounds = true
    }
    
    // 更新渐变层属性
    private func updateGradientLayer() {
        gradientLayer.colors = gradientColors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.locations = locations
    }
    
    // 确保渐变层大小与按钮一致
    open override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
