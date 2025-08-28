//
//  AMVolumeWaveformView.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/8/20.
//  Copyright © 2025 shenxiaofei. All rights reserved.
//

import UIKit

class AMVolumeWaveformView: UIView {
    
    /// 外部设置的分贝值 (0 ~ 1，或者 -∞ ~ 0 dB 归一化后)
    var level: CGFloat = 0.0 {
        didSet {
            // 在 updateWave() 里
            let normalized: CGFloat
            if level < 0.3 {
                normalized = 0.0
            } else {
                normalized = (level - 0.2) / 0.7 // 映射到 0 ~ 1
            }
            targetAmplitude = max(0, min(1, normalized))
        }
    }
    
    private var lineLayers: [CALayer] = []
    private var displayLink: CADisplayLink?
    
    private var phase: CGFloat = 0
    private var targetAmplitude: CGFloat = 0
    private var currentAmplitude: CGFloat = 0
    
    private let lineHeight: CGFloat = 6
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
//        startAnimation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
//        startAnimation()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 避免重复创建
        if !lineLayers.isEmpty { return }
        
        let lineWidth: CGFloat = 3
        let spacing: CGFloat = 5
        let count = Int(bounds.width / spacing)
        
        for i in 0..<count {
            let lineLayer = CALayer()
            lineLayer.backgroundColor = UIColor.white.cgColor
            lineLayer.frame = CGRect(
                x: CGFloat(i) * spacing,
                y: bounds.midY,
                width: lineWidth,
                height: lineHeight // 初始高度
            )
            lineLayer.cornerRadius = lineWidth / 2
            lineLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5) // 垂直居中缩放
            layer.addSublayer(lineLayer)
            lineLayers.append(lineLayer)
        }
    }
    
    func startAnimation() {
        if displayLink == nil {
            displayLink = CADisplayLink(target: self, selector: #selector(updateWave))
            displayLink?.add(to: .main, forMode: .common)
        }
    }
    
    func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updateWave() {
        phase += 0.15 // 控制水波纹扩散速度
        
        // 逐渐逼近 targetAmplitude（模拟衰减/增强）
        currentAmplitude += (targetAmplitude - currentAmplitude) * 0.1
        
        let baseHeight: CGFloat = bounds.height - 8
        
        for (i, line) in lineLayers.enumerated() {
            let x = CGFloat(i)
            let value = sin((x / 10.0) + phase) // 正弦函数
            
            // 振幅受 decibel 控制
            var height = baseHeight * (value * currentAmplitude)
            
            // 抖动 + 高频闪烁
            let flicker = sin(phase * 12 + x) * 2
            let jitter = CGFloat.random(in: -4...4) + flicker
            height += jitter * max(0.5, currentAmplitude)
            
            // 更新 frame (垂直居中)
            line.bounds.size.height = max(lineHeight, abs(height))
            line.position.y = bounds.midY
        }
    }
    
    deinit {
        stopAnimation()
    }
}
