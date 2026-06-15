//
//  AMUIStackPassthroughView.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/8/15.
//  Copyright © 2025 fei. All rights reserved.

import UIKit

/// 基于 `UIStackView` 的点击穿透容器。
///
/// 与 `AMPassthroughView` 类似，额外处理点击点落在 Stack 布局区域外、但子视图仍可能响应的情况。
@objc(AMUIStackPassthroughView)
@IBDesignable
@objcMembers
open class AMUIStackPassthroughView: UIStackView {

    /// 是否允许点击穿透（默认 `false`）
    @IBInspectable open var allowHitTestPassthrough: Bool = false

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        allowHitTestPassthrough = false
    }

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard allowHitTestPassthrough else {
            return super.hitTest(point, with: event)
        }

        let pointInsideSelf = bounds.contains(point)

        if !pointInsideSelf {
            for subview in subviews.reversed() {
                let converted = subview.convert(point, from: self)
                if let hit = subview.hitTest(converted, with: event) {
                    return hit
                }
            }
            return nil
        }

        return super.hitTest(point, with: event)
    }
}
