//
//  AMCircularProgressView.swift
//  ChinaHomelife247
//
//  Created by shenxiaofei on 2026/3/24.
//  Copyright shenxiaofei. All rights reserved.
//

import UIKit

class AMCircularProgressView: UIView {
    private let progressLayer = CAShapeLayer()
    private let trackLayer = CAShapeLayer()
    
    var progress: CGFloat = 0 {
        didSet { progressLayer.strokeEnd = progress }
    }
    var lineWidth: CGFloat = 3
    var progressColor: UIColor = UIColor.hex(string: "E2E8F0") {
        didSet { progressLayer.strokeColor = progressColor.cgColor }
    }
    var trackColor: UIColor = .clear {
        didSet { trackLayer.strokeColor = trackColor.cgColor }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 10
        let path = UIBezierPath(arcCenter: center,
                                radius: radius,
                                startAngle: -.pi / 2,  // 从顶部开始
                                endAngle: .pi * 1.5,
                                clockwise: true)
        // 轨道层
        trackLayer.path = path.cgPath
        trackLayer.strokeColor = trackColor.cgColor
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineWidth = lineWidth
        if trackLayer.superlayer == nil {
            layer.addSublayer(trackLayer)
        }
        
        // 进度层
        progressLayer.path = path.cgPath
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.strokeEnd = progress
        progressLayer.lineCap = .round  // 圆角端点
        if progressLayer.superlayer == nil {
            layer.addSublayer(progressLayer)
        }
    }
    
    // 带动画更新进度
    func setProgress(_ value: CGFloat, animated: Bool = true) {
        if animated {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = progressLayer.strokeEnd
            animation.toValue = value
            animation.duration = 0.3
            progressLayer.add(animation, forKey: "progressAnim")
        }
        progressLayer.strokeEnd = value
        progress = value
    }
}
