//
//  UIView+AMFloating.swift
//  ChinaHomelife247
//
//  Created by shenxiaofei on 2025/11/26.
//  Copyright © 2025 shenxiaofei. All rights reserved.
//

import UIKit

// MARK: - 拖动配置辅助类（存储所有相关属性）
private class AMDragConfiguration {
    /// 是否启用磁吸贴右
    var enableMagnetToRight: Bool
    /// 磁吸时与右边的间距
    var magnetOffset: CGFloat
    /// 拖动边界Insets
    var edgeInsets: UIEdgeInsets
    /// 开始拖动回调
    var didStartDragging: (() -> Void)?
    /// 拖动中回调
    var didDrag: ((CGPoint) -> Void)?
    /// 结束拖动回调
    var didEndDragging: ((CGPoint) -> Void)?
    /// 拖动手势（用于后续移除）
    weak var panGesture: UIPanGestureRecognizer? // 弱引用避免循环引用
    
    // 初始化配置
    init(
        enableMagnetToRight: Bool,
        magnetOffset: CGFloat,
        edgeInsets: UIEdgeInsets,
        didStartDragging: (() -> Void)?,
        didDrag: ((CGPoint) -> Void)?,
        didEndDragging: ((CGPoint) -> Void)?
    ) {
        self.enableMagnetToRight = enableMagnetToRight
        self.magnetOffset = magnetOffset
        self.edgeInsets = edgeInsets
        self.didStartDragging = didStartDragging
        self.didDrag = didDrag
        self.didEndDragging = didEndDragging
    }
}

// MARK: - UIView 拖动+磁吸贴右扩展
extension UIView {
    /// 关联对象Key（仅需一个，绑定DragConfiguration）
    private enum AssociatedKey {
        static var dragConfig: Void?
    }
    
    /// 为视图添加拖动能力（支持自动磁吸贴右）
    /// - Parameters:
    ///   - enableMagnetToRight: 是否启用磁吸贴右（默认 true）
    ///   - magnetOffset: 磁吸时与右边的间距（默认 0）
    ///   - edgeInsets: 拖动边界限制（默认 .zero）
    ///   - didStartDragging: 开始拖动回调（可选）
    ///   - didDrag: 拖动中回调（可选）
    ///   - didEndDragging: 结束拖动回调（可选）
    func addDraggable(
        enableMagnetToRight: Bool = true,
        magnetOffset: CGFloat = 0,
        edgeInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0),
        didStartDragging: (() -> Void)? = nil,
        didDrag: ((CGPoint) -> Void)? = nil,
        didEndDragging: ((CGPoint) -> Void)? = nil
    ) {
        // 1. 移除已有的拖动配置和手势（避免重复添加）
        removeDraggable()
        
        // 2. 创建拖动手势
        let panGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handleDragGesture(_:))
        )
        
        // 3. 创建配置对象，存储所有参数
        let config = AMDragConfiguration(
            enableMagnetToRight: enableMagnetToRight,
            magnetOffset: magnetOffset,
            edgeInsets: edgeInsets,
            didStartDragging: didStartDragging,
            didDrag: didDrag,
            didEndDragging: didEndDragging
        )
        config.panGesture = panGesture
        
        // 4. 关联配置对象（仅需一次关联）
        objc_setAssociatedObject(
            self,
            &AssociatedKey.dragConfig,
            config,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        // 5. 添加手势
        addGestureRecognizer(panGesture)
    }
    
    /// 移除视图的拖动能力
    func removeDraggable() {
        // 1. 获取配置对象
        guard let config = objc_getAssociatedObject(self, &AssociatedKey.dragConfig) as? AMDragConfiguration else {
            return
        }
        
        // 2. 移除拖动手势
        if let panGesture = config.panGesture {
            removeGestureRecognizer(panGesture)
        }
        
        // 3. 清空关联对象（释放配置）
        objc_setAssociatedObject(self, &AssociatedKey.dragConfig, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    /// 获取当前拖动配置（内部使用）
    private var dragConfig: AMDragConfiguration? {
        return objc_getAssociatedObject(self, &AssociatedKey.dragConfig) as? AMDragConfiguration
    }
}

// MARK: - 拖动逻辑处理
private extension UIView {
    @objc func handleDragGesture(_ gesture: UIPanGestureRecognizer) {
        guard let superview = superview, let config = dragConfig else {
            return
        }
        
        // 从配置对象中获取所有参数（无需多次获取关联对象）
        let enableMagnet = config.enableMagnetToRight
        let magnetOffset = config.magnetOffset
        let edgeInsets = config.edgeInsets
        let didStart = config.didStartDragging
        let didDrag = config.didDrag
        let didEnd = config.didEndDragging
        
        switch gesture.state {
        case .began:
            didStart?()
            bringSubviewToFront(self) // 拖动时置顶
            
        case .changed:
            let translation = gesture.translation(in: superview)
            var newCenterX = center.x + translation.x
            var newCenterY = center.y + translation.y
            
            // 限制拖动边界
            let maxX = superview.bounds.width - bounds.width/2 - edgeInsets.right
            let minX = bounds.width/2 + edgeInsets.left
            let maxY = superview.bounds.height - bounds.height/2 - edgeInsets.bottom
            let minY = bounds.height/2 + edgeInsets.top
            
            newCenterX = max(min(newCenterX, maxX), minX)
            newCenterY = max(min(newCenterY, maxY), minY)
            
            center = CGPoint(x: newCenterX, y: newCenterY)
            didDrag?(center)
            
            // 重置偏移量
            gesture.setTranslation(.zero, in: superview)
            
        case .ended, .cancelled, .failed:
            var finalCenter = center
            if enableMagnet {
                // 磁吸贴右动画
                let rightEdge = superview.bounds.width - bounds.width/2 - magnetOffset
                UIView.animate(withDuration: 0.2) {
                    self.center.x = rightEdge
                } completion: { _ in
                    finalCenter = self.center
                    didEnd?(finalCenter)
                }
            } else {
                didEnd?(finalCenter)
            }
            
        default:
            break
        }
    }
}
