//
//  AMLayoutRelation.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/8/21.
//  Copyright © 2025 shen xiaofei. All rights reserved.
//

protocol AMLayoutRelation {
    func equalToSuper(view superview: AMFrameLayoutAnchor) -> AMFrameLayoutAnchor
    func equalTo(sameLevelView: AMFrameLayoutAnchor) -> AMFrameLayoutAnchor
    func offset(_ value: CGFloat) -> AMFrameLayoutAnchor
    
    func apply()
}
