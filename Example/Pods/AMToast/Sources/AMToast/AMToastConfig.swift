//
//  AMToastConfig.swift
//  AMToast
//
//  Created by shen xiaofei on 2025/6/3.
//

import UIKit

public struct AMToastConfig {
    public static var defaultDuration = 2.0
    public static var successDuration = 2.0
    
    //toastview style default
    public struct ToastViewStyle {
        public static var cornerRadius = 18.0
        
        // 背景颜色配置
        public static var backgroundColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ?
                UIColor(white: 0.2, alpha: 0.94) :
                UIColor.black.withAlphaComponent(0.94)
        }
        
        // 文字颜色配置
        public static var textColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ?
                .label :
                .white
        }
        
        // 字体配置
        public static var textFont: UIFont = UIFont.systemFont(ofSize: 14)
    }
    
    public struct Window {
        public static var defaultWindowLevel = UIWindow.Level.statusBar - 1 {
            didSet {
                AMToastWindow.shared.windowLevel = defaultWindowLevel
            }
        }
    }
    
    public struct Position {
        public static var topMarginPortrait: CGFloat = 60.0
        public static var topMarginLandscape: CGFloat = 20.0
    }
    
    // 重置所有配置为默认值
    public static func resetToDefault() {
        defaultDuration = 2.0
        successDuration = 2.0
        ToastViewStyle.cornerRadius = 18.0
        ToastViewStyle.backgroundColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ?
                UIColor(white: 0.2, alpha: 0.94) :
                UIColor.black.withAlphaComponent(0.94)
        }
        ToastViewStyle.textColor = AMToastConfig.ToastViewStyle.textColor
        ToastViewStyle.textFont = UIFont.systemFont(ofSize: 14)
        Window.defaultWindowLevel = UIWindow.Level.statusBar - 1
        Position.topMarginPortrait = 60.0
        Position.topMarginLandscape = 20.0
    }
}
