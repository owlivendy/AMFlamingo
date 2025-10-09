//
//  CHAgentChatBubbleView.swift
//  ChinaHomelife247
//
//  Created by shen xiaofei on 2025/8/15.
//  Copyright © 2025 fei. All rights reserved.
//

import UIKit

class AMBubbleView: UIView {
    
    var maskedCorners: CACornerMask = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner] {
        didSet {
            layer.maskedCorners = maskedCorners
        }
    }

    private var gradientLayer: CAGradientLayer?
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 10
        layer.maskedCorners = maskedCorners
        backgroundColor = .systemBlue
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let gradientLayer = gradientLayer else {return}
        gradientLayer.frame = self.bounds
        gradientLayer.cornerRadius = layer.cornerRadius
        gradientLayer.masksToBounds = true
    }
    
    func setGradientLayer(colors:[UIColor], startPoints:CGPoint, endPoints:CGPoint) {
        let gralayer = CAGradientLayer()
        gralayer.colors = colors.map({ $0.cgColor })
        gralayer.startPoint = startPoints
        gralayer.endPoint = endPoints
        gradientLayer = gralayer
        
        self.layer.addSublayer(gralayer)
    }
}
