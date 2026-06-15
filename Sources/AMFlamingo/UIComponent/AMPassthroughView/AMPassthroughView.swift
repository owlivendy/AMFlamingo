//
//  AMPassthroughView.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/8/15.
//  Copyright © 2025 fei. All rights reserved.

import UIKit

/// 点击穿透视图：开启 `allowHitTestPassthrough` 后，自身空白区域不拦截触摸，子视图仍可响应。
///
/// 典型场景：全屏透明/半透明遮罩盖在页面上，需要点击下方按钮，同时保留遮罩上的浮动控件可点。
@objc(AMPassthroughView)
@IBDesignable
@objcMembers
open class AMPassthroughView: UIView {

    /// 是否允许点击穿透自身空白区域（默认 `false`）
    @IBInspectable open var allowHitTestPassthrough: Bool = false

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        allowHitTestPassthrough = false
    }

    open override func hitTest(_ hitPoint: CGPoint, with event: UIEvent?) -> UIView? {
        guard allowHitTestPassthrough else {
            return super.hitTest(hitPoint, with: event)
        }

        guard isUserInteractionEnabled, !isHidden, alpha >= 0.01 else {
            return nil
        }

        guard point(inside: hitPoint, with: event) else {
            return nil
        }

        for subview in subviews.reversed() {
            let converted = subview.convert(hitPoint, from: self)
            if let hit = subview.hitTest(converted, with: event) {
                return hit
            }
        }

        return nil
    }
}
