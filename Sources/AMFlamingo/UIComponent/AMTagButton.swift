//
//  AMTagButton.swift
//  AMFlamingo
//
//  Created by meotech on 2025/10/28.
//

import UIKit

// 定义按钮类型枚举
public enum AMTagButtonType {
    case `default`  // 默认类型（不可交互）
    case selected   // 可选中类型（可交互）
}

open class CHTagButton: AMButton {  // 继承自之前实现的 CHButton
    
    // 初始化方法（指定类型）
    public init(type: AMTagButtonType) {
        super.init(frame: .zero)
        commonInit(type: type)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit(type: AMTagButtonType) {
        // 基础样式配置
        layer.cornerRadius = 4
        titleLabel?.font = UIFont.systemFont(ofSize: 12)
        
        // 默认状态样式
        setBackgroundColor(UIColor.am_line, for: .normal)
        setTitleColor(UIColor.am_secondText, for: .normal)
        setTextInsets(UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4))
        
        // 根据类型配置交互和选中状态样式
        switch type {
        case .default:
            isUserInteractionEnabled = false
        case .selected:
            isUserInteractionEnabled = true
            // 选中状态样式
            setBackgroundColor(UIColor.am_themeBlue.withAlphaComponent(0.1), for: .selected)
            setBorderColor(UIColor.am_themeBlue, for: .selected)
            setBorderWidth(1, for: .selected)
            setTitleColor(UIColor.am_themeBlue, for: .selected)
        }
    }
    
    // 重写 intrinsicContentSize，补偿 titleEdgeInsets 的空间
    open override var intrinsicContentSize: CGSize {
        // 计算标题原始尺寸
        titleLabel?.sizeToFit()
        let originalSize = titleLabel?.bounds.size ?? .zero
        
        // 叠加 edgeInsets 补偿
        let extraWidth = titleEdgeInsets.left + titleEdgeInsets.right
        let extraHeight = titleEdgeInsets.top + titleEdgeInsets.bottom
        
        return CGSize(
            width: originalSize.width + extraWidth,
            height: originalSize.height + extraHeight
        )
    }
    
    // 设置标题内边距（封装 titleEdgeInsets）
    open func setTextInsets(_ insets: UIEdgeInsets) {
        titleEdgeInsets = insets
    }
    
    // 文本访问器（映射到 title）
    open var text: String? {
        get { title(for: .normal) }
        set { setTitle(newValue, for: .normal) }
    }
}
