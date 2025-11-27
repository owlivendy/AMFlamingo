//
//  AMNavigationBar.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/10/13.
//  Copyright © 2025 shen xiaofei. All rights reserved.
//

import UIKit

open class AMTextField: UITextField {
    // 输入类型枚举
    public enum InputType {
        case text
        case number
        case numericValue
    }
    
    // 自定义委托，用于转发常用的UITextFieldDelegate方法
    public weak var amDelegate: UITextFieldDelegate?
    
    // 当前输入类型
    open var type: InputType = .text {
        didSet {
            configureForType()
        }
    }
    
    // 字符数限制（仅 type = .text 时有效）
    open var maxCharacterCount: Int = 0 {
        didSet {
            if type == .text {
                validateTextLimit()
            }
        }
    }
    
    // 数值范围限制（仅 type = .numericValue 时有效）
    open var valueRange: ClosedRange<Int>? {
        didSet {
            if type == .numericValue {
                validateNumericValue()
            }
        }
    }
    
    // 初始化
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    // 公共初始化设置
    private func commonInit() {
        borderStyle = .roundedRect
        delegate = self
        addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        configureForType()
    }
    
    // 根据类型配置文本框
    private func configureForType() {
        switch type {
        case .text:
            keyboardType = .default
            autocapitalizationType = .sentences
            validateTextLimit()
            
        case .number:
            keyboardType = .numberPad
            text = nil
            
        case .numericValue:
            keyboardType = .numberPad
            validateNumericValue()
        }
    }
    
    // 验证文本长度限制
    private func validateTextLimit() {
        guard type == .text, maxCharacterCount > 0, let currentText = text else { return }
        
        if currentText.count > maxCharacterCount {
            text = String(currentText.prefix(maxCharacterCount))
        }
    }
    
    // 验证数值输入
    private func validateNumericValue() {
        guard type == .numericValue, let currentText = text else { return }
        
        // 过滤非数字字符
        let filteredText = currentText.filter { $0.isNumber }
        if filteredText != currentText {
            text = filteredText
            return
        }
        
        // 处理开头为0的情况（长度大于1时）
        if filteredText.count > 1, filteredText.starts(with: "0") {
            text = String(filteredText.dropFirst())
            return
        }
        
        // 验证数值范围
        guard let range = valueRange, let value = Int(filteredText) else { return }
        
        if value < range.lowerBound {
            text = String(range.lowerBound)
        } else if value > range.upperBound {
            text = String(range.upperBound)
        }
    }
    
    // 文本变化事件
    @objc private func textDidChange() {
        switch type {
        case .text:
            validateTextLimit()
        case .number:
            text = text?.filter { $0.isNumber }
        case .numericValue:
            validateNumericValue()
        }
    }
}

// MARK: - UITextFieldDelegate
extension AMTextField: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // 先执行自定义逻辑
        let shouldChange: Bool
        switch type {
        case .text:
            guard maxCharacterCount > 0 else {
                shouldChange = true
                break
            }
            
            let currentText = text ?? ""
            let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
            shouldChange = newText.count <= maxCharacterCount
            
        case .number:
            // 只允许数字输入
            let allowedCharacters = CharacterSet.decimalDigits
            let inputCharacters = CharacterSet(charactersIn: string)
            shouldChange = allowedCharacters.isSuperset(of: inputCharacters)
            
        case .numericValue:
            // 只允许数字输入
            shouldChange = true
        }
        
        // 如果自定义逻辑允许改变，再询问amDelegate
        if shouldChange {
            return amDelegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string) ?? true
        }
        return false
    }
    
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // 先询问amDelegate，如果没有设置或返回true，再执行默认逻辑
        return amDelegate?.textFieldShouldBeginEditing?(textField) ?? true
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        // 转发给amDelegate
        amDelegate?.textFieldDidBeginEditing?(textField)
    }
    
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return amDelegate?.textFieldShouldEndEditing?(textField) ?? true
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        amDelegate?.textFieldDidEndEditing?(textField)
    }
    
    public func textFieldShouldClear(_ textField: UITextField) -> Bool {
        let shouldClear = amDelegate?.textFieldShouldClear?(textField) ?? true
        if shouldClear {
            // 清除文本后执行对应验证
            switch type {
            case .text:
                validateTextLimit()
            case .numericValue:
                validateNumericValue()
            case .number:
                break
            }
        }
        return shouldClear
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return amDelegate?.textFieldShouldReturn?(textField) ?? true
    }
}
