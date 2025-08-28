//
//  AMAttributedStringBuilder.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/7/2.
//  Copyright © 2025 shen xiaofei. All rights reserved.
//

import UIKit

public class AMAttributedStringBuilder {
    private var parts: [(text: String, fontSize: CGFloat?, weight: UIFont.Weight?, color: UIColor?)] = []
    
    // MARK: - 初始化
    public init() {}
    
    public convenience init(_ text: String,
                            color: UIColor? = nil,
                            fontSize: CGFloat? = nil,
                            weight: UIFont.Weight? = nil) {
        self.init()
        parts.append((text, fontSize, weight, color))
    }
    
    // MARK: - 拼接
    @discardableResult
    public func append(_ text: String,
                       color: UIColor? = nil,
                       fontSize: CGFloat? = nil,
                       weight: UIFont.Weight? = nil) -> AMAttributedStringBuilder {
        
        var inheritFontSize = fontSize
        var inheritWeight = weight
        var inheritColor = color
        
        if let last = parts.last {
            if inheritFontSize == nil { inheritFontSize = last.fontSize }
            if inheritWeight == nil { inheritWeight = last.weight }
            if inheritColor == nil { inheritColor = last.color }
        }
        
        parts.append((text, inheritFontSize, inheritWeight, inheritColor))
        return self
    }
    
    // MARK: - 运算符 +
    public static func + (lhs: AMAttributedStringBuilder, rhs: AMAttributedStringBuilder) -> AMAttributedStringBuilder {
        let builder = AMAttributedStringBuilder()
        builder.parts = lhs.parts
        
        if let last = lhs.parts.last {
            var newParts: [(String, CGFloat?, UIFont.Weight?, UIColor?)] = []
            for (t, fs, w, c) in rhs.parts {
                let fontSize = fs ?? last.fontSize
                let weight = w ?? last.weight
                let color = c ?? last.color
                newParts.append((t, fontSize, weight, color))
            }
            builder.parts.append(contentsOf: newParts)
        } else {
            builder.parts.append(contentsOf: rhs.parts)
        }
        
        return builder
    }
    
    // MARK: - 输出 NSAttributedString
    public var attribute: NSAttributedString {
        let result = NSMutableAttributedString()
        for part in parts {
            var attrs: [NSAttributedString.Key: Any] = [:]
            
            if let size = part.fontSize {
                let weight = part.weight ?? .regular
                attrs[.font] = UIFont.systemFont(ofSize: size, weight: weight)
            }
            if let color = part.color {
                attrs[.foregroundColor] = color
            }
            
            result.append(NSAttributedString(string: part.text, attributes: attrs))
        }
        return result
    }
}

// MARK: - String 扩展
public extension String {
    func attribute(color: UIColor? = nil,
                   fontSize: CGFloat? = nil,
                   weight: UIFont.Weight? = nil) -> AMAttributedStringBuilder {
        return AMAttributedStringBuilder(self, color: color, fontSize: fontSize, weight: weight)
    }
}
