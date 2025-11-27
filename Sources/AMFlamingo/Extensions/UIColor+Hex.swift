//
//  UIColor+Hex.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/8/28.
//

import UIKit

public extension UIColor {
    /// 使用十六进制字符串创建UIColor
    /// - Parameter hexString: 十六进制颜色字符串，支持格式：#RGB、#RGBA、#RRGGBB、#RRGGBBAA、RGB、RGBA、RRGGBB、RRGGBBAA
    static func hex(string: String, alpha: CGFloat? = nil) -> UIColor {
        // 移除可能存在的#前缀
        var cleanedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedString.hasPrefix("#") {
            cleanedString.remove(at: cleanedString.startIndex)
        }
        
        // 检查字符串长度是否合法
        let length = cleanedString.count
        guard length == 3 || length == 4 || length == 6 || length == 8 else {
            return UIColor.white
        }
        
        // 转换为全大写，便于处理
        let hexString = cleanedString.uppercased()
        
        // 定义扫描器
        let scanner = Scanner(string: hexString)
        var hexNumber: UInt64 = 0
        
        // 扫描十六进制数值
        guard scanner.scanHexInt64(&hexNumber) else {
            return UIColor.white
        }
        
        // 根据长度解析RGB和Alpha值
        var red: UInt64, green: UInt64, blue: UInt64, alphaTmp: UInt64 = 0xFF
        
        switch length {
        case 3: // RGB (每两位重复)
            red = (hexNumber >> 8) * 0x11
            green = ((hexNumber >> 4) & 0x0F) * 0x11
            blue = (hexNumber & 0x0F) * 0x11
        case 4: // RGBA (每两位重复)
            red = (hexNumber >> 12) * 0x11
            green = ((hexNumber >> 8) & 0x0F) * 0x11
            blue = ((hexNumber >> 4) & 0x0F) * 0x11
            alphaTmp = (hexNumber & 0x0F) * 0x11
        case 6: // RRGGBB
            red = (hexNumber >> 16) & 0xFF
            green = (hexNumber >> 8) & 0xFF
            blue = hexNumber & 0xFF
        case 8: // RRGGBBAA
            red = (hexNumber >> 24) & 0xFF
            green = (hexNumber >> 16) & 0xFF
            blue = (hexNumber >> 8) & 0xFF
            alphaTmp = hexNumber & 0xFF
        default:
            return UIColor.white
        }
        
        if var alpha = alpha {
            if alpha > 1.0 {
                alpha = 1.0
            } else if alpha < 0 {
                alpha = 0
            }
            alphaTmp = UInt64(alpha * 255)
        }
        
        // 初始化颜色 (将0-255范围转换为0-1范围)
        return UIColor.init(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: CGFloat(alphaTmp) / 255.0
        )
    }
}
