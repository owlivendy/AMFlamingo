//
//  AMButton.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/10/28.
//

import UIKit

class AMButton: UIButton {
    // 存储不同状态对应的属性（key: UIControl.State 的原始值）
    private var backgroundColors: [UInt: UIColor] = [:]
    private var borderColors: [UInt: UIColor] = [:]
    private var borderWidths: [UInt: CGFloat] = [:]
    
    // 初始化方法
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        // 初始化时可添加默认配置（如默认边框宽度为0等）
    }
    
    // MARK: - 公开方法：为不同状态设置属性
    
    /// 为指定状态设置背景色
    func setBackgroundColor(_ color: UIColor?, for state: UIControl.State) {
        guard let color = color else {
            backgroundColors.removeValue(forKey: state.rawValue)
            return
        }
        backgroundColors[state.rawValue] = color
    }
    
    /// 为指定状态设置边框色
    func setBorderColor(_ color: UIColor?, for state: UIControl.State) {
        guard let color = color else {
            borderColors.removeValue(forKey: state.rawValue)
            return
        }
        borderColors[state.rawValue] = color
    }
    
    /// 为指定状态设置边框宽度
    func setBorderWidth(_ width: CGFloat, for state: UIControl.State) {
        borderWidths[state.rawValue] = width
    }
    
    // MARK: - 布局时更新状态属性
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 更新背景色（优先使用当前状态对应的颜色）
        if let bgColor = backgroundColors[state.rawValue] {
            backgroundColor = bgColor
        }
        
        // 更新边框色
        if let borderColor = borderColors[state.rawValue] {
            layer.borderColor = borderColor.cgColor
        }
        
        // 更新边框宽度
        if let borderWidth = borderWidths[state.rawValue] {
            layer.borderWidth = borderWidth
        }
    }
}
