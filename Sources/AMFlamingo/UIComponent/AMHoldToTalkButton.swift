//
//  AMHoldToTalkButton.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/7/2.
//  Copyright © 2025 shen xiaofei. All rights reserved.
//


import UIKit

open class AMHoldToTalkButton: UIButton {
    // 状态枚举
    public enum HoldStatus {
        case uninitial  // 初始状态
        case inner      // 上滑距离未超过100px
        case outer      // 上滑超过100px
    }
    
    // 配置参数 - 可根据需求调整
    /// 触发滑动动作的阈值(px)
    private let slideThreshold: CGFloat = 60
    /// 滑动检测的容错值(px)，避免轻微抖动误判
    private let slideTolerance: CGFloat = 5
    
    // 状态记录
    private var isHolding = false            // 是否处于按住状态
    private var startPoint: CGPoint = .zero  // 手指按下的初始位置
    private var currentSlideDistance: CGFloat = 0 // 当前滑动距离（上滑为正，下滑为负）
    // 当前持有状态
    private var holdStatus: HoldStatus = .uninitial {
        didSet {
            switch holdStatus {
            case .uninitial:
                setTitle("按住 说话", for: .normal)
            case .inner:
                setTitle("松开 发送", for: .normal)
            case .outer:
                setTitle("松手 取消", for: .normal)
            }
            onHoldStatusChange?(holdStatus)
        }
    }
    
    // 回调闭包 - 对外暴露的事件接口
    /// 按住动作回调
    open var onHoldBegan: (() -> Void)?
    /// 松手动作回调
    open var onHoldEnded: ((HoldStatus) -> Void)?
    /// 状态变化回调
    open var onHoldStatusChange: ((HoldStatus) -> Void)?
    
    // 初始化方法
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    // 公共初始化逻辑
    private func commonInit() {
        setupUI()
    }
    
    // UI配置
    private func setupUI() {
        // 基础样式
        setTitle("按住 说话", for: .normal)
        
        // 禁用默认高亮效果，手动控制状态
        adjustsImageWhenHighlighted = false
        showsTouchWhenHighlighted = false
    }
    
    // MARK: - 触摸事件处理
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        
        // 记录初始状态
        isHolding = true
        startPoint = touch.location(in: self.superview)
        currentSlideDistance = 0
        holdStatus = .inner // 触摸开始时设置为inner状态
        
        // 触发按住回调
        onHoldBegan?()
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard isHolding, let touch = touches.first else { return }
        
        // 计算当前滑动距离（上滑为正，下滑为负）
        let currentPoint = touch.location(in: self.superview)
        currentSlideDistance = startPoint.y - currentPoint.y
        
        // 检测上滑超过100px
        if currentSlideDistance >= (slideThreshold - slideTolerance) {
            if holdStatus != .outer {
                holdStatus = .outer
            }
        }
        // 检测滑动在阈值内（包括下滑）
        else if currentSlideDistance < (slideThreshold - slideTolerance) {
            if holdStatus != .inner {
                holdStatus = .inner
            }
        }
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        handleRelease()
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        handleRelease()
    }
    
    // 处理松手逻辑
    private func handleRelease() {
        guard isHolding else { return }
        isHolding = false
        
        // 触发松手回调，传递当前状态
        onHoldEnded?(holdStatus)
        
        // 重置状态为初始值
        holdStatus = .uninitial
    }
}
