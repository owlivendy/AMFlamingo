import UIKit

/// 按钮图片位置样式
public enum AMImagePositionStyle: UInt {
    /// 图片在左，文字在右
    case `default`
    /// 图片在右，文字在左
    case right
    /// 图片在上，文字在下
    case top
    /// 图片在下，文字在上
    case bottom
}

public extension UIButton {
    /// 设置图片与文字样式
    /// - Parameters:
    ///   - imagePositionStyle: 图片位置样式
    ///   - spacing: 图片与文字之间的间距
    func am_imagePositionStyle(_ imagePositionStyle: AMImagePositionStyle, spacing: CGFloat) {
        if imagePositionStyle == .default {
            if contentHorizontalAlignment == .left {
                titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: 0)
            } else if contentHorizontalAlignment == .right {
                imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: spacing)
            } else {
                imageEdgeInsets = UIEdgeInsets(top: 0, left: -0.5 * spacing, bottom: 0, right: 0.5 * spacing)
                titleEdgeInsets = UIEdgeInsets(top: 0, left: 0.5 * spacing, bottom: 0, right: -0.5 * spacing)
            }
        } else if imagePositionStyle == .right {
            let imageW = imageView?.image?.size.width ?? 0
            let titleW = titleLabel?.frame.size.width ?? 0
            if contentHorizontalAlignment == .left {
                imageEdgeInsets = UIEdgeInsets(top: 0, left: titleW + spacing, bottom: 0, right: 0)
                titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageW, bottom: 0, right: 0)
            } else if contentHorizontalAlignment == .right {
                imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -titleW)
                titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: imageW + spacing)
            } else {
                let imageOffset = titleW + 0.5 * spacing
                let titleOffset = imageW + 0.5 * spacing
                imageEdgeInsets = UIEdgeInsets(top: 0, left: imageOffset, bottom: 0, right: -imageOffset)
                titleEdgeInsets = UIEdgeInsets(top: 0, left: -titleOffset, bottom: 0, right: titleOffset)
            }
        } else if imagePositionStyle == .top {
            let imageW = imageView?.frame.size.width ?? 0
            let imageH = imageView?.frame.size.height ?? 0
            let titleIntrinsicContentSizeW = titleLabel?.intrinsicContentSize.width ?? 0
            let titleIntrinsicContentSizeH = titleLabel?.intrinsicContentSize.height ?? 0
            imageEdgeInsets = UIEdgeInsets(top: -titleIntrinsicContentSizeH - spacing, left: 0, bottom: 0, right: -titleIntrinsicContentSizeW)
            titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageW, bottom: -imageH - spacing, right: 0)
        } else if imagePositionStyle == .bottom {
            let imageW = imageView?.frame.size.width ?? 0
            let imageH = imageView?.frame.size.height ?? 0
            let titleIntrinsicContentSizeW = titleLabel?.intrinsicContentSize.width ?? 0
            let titleIntrinsicContentSizeH = titleLabel?.intrinsicContentSize.height ?? 0
            imageEdgeInsets = UIEdgeInsets(top: titleIntrinsicContentSizeH + spacing, left: 0, bottom: 0, right: -titleIntrinsicContentSizeW)
            titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageW, bottom: imageH + spacing, right: 0)
        }
    }
    
    /// 设置图片与文字样式（推荐使用）
    /// - Parameters:
    ///   - imagePositionStyle: 图片位置样式
    ///   - spacing: 图片与文字之间的间距
    ///   - imagePositionBlock: 在此 Block 中设置按钮的图片、文字以及 contentHorizontalAlignment 属性
    func am_imagePositionStyle(_ imagePositionStyle: AMImagePositionStyle, spacing: CGFloat, imagePositionBlock: (UIButton) -> Void) {
        imagePositionBlock(self)
        
        if imagePositionStyle == .default {
            if contentHorizontalAlignment == .left {
                titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: 0)
            } else if contentHorizontalAlignment == .right {
                imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: spacing)
            } else {
                imageEdgeInsets = UIEdgeInsets(top: 0, left: -0.5 * spacing, bottom: 0, right: 0.5 * spacing)
                titleEdgeInsets = UIEdgeInsets(top: 0, left: 0.5 * spacing, bottom: 0, right: -0.5 * spacing)
            }
        } else if imagePositionStyle == .right {
            let imageW = imageView?.image?.size.width ?? 0
            let titleW = titleLabel?.frame.size.width ?? 0
            if contentHorizontalAlignment == .left {
                imageEdgeInsets = UIEdgeInsets(top: 0, left: titleW + spacing, bottom: 0, right: 0)
                titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageW, bottom: 0, right: 0)
            } else if contentHorizontalAlignment == .right {
                imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -titleW)
                titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: imageW + spacing)
            } else {
                let imageOffset = titleW + 0.5 * spacing
                let titleOffset = imageW + 0.5 * spacing
                imageEdgeInsets = UIEdgeInsets(top: 0, left: imageOffset, bottom: 0, right: -imageOffset)
                titleEdgeInsets = UIEdgeInsets(top: 0, left: -titleOffset, bottom: 0, right: titleOffset)
            }
        } else if imagePositionStyle == .top {
            let imageW = imageView?.frame.size.width ?? 0
            let imageH = imageView?.frame.size.height ?? 0
            let titleIntrinsicContentSizeW = titleLabel?.intrinsicContentSize.width ?? 0
            let titleIntrinsicContentSizeH = titleLabel?.intrinsicContentSize.height ?? 0
            imageEdgeInsets = UIEdgeInsets(top: -titleIntrinsicContentSizeH - spacing, left: 0, bottom: 0, right: -titleIntrinsicContentSizeW)
            titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageW, bottom: -imageH - spacing, right: 0)
        } else if imagePositionStyle == .bottom {
            let imageW = imageView?.frame.size.width ?? 0
            let imageH = imageView?.frame.size.height ?? 0
            let titleIntrinsicContentSizeW = titleLabel?.intrinsicContentSize.width ?? 0
            let titleIntrinsicContentSizeH = titleLabel?.intrinsicContentSize.height ?? 0
            imageEdgeInsets = UIEdgeInsets(top: titleIntrinsicContentSizeH + spacing, left: 0, bottom: 0, right: -titleIntrinsicContentSizeW)
            titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageW, bottom: imageH + spacing, right: 0)
        }
    }
} 