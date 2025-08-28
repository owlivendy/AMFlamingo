//
//  AMFrameLayout.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/7/2.
//  Copyright © 2025 shen xiaofei. All rights reserved.
//


typealias AMFrameLayoutMakerCallback = ((AMFrameLayoutMaker)->(Void))

extension UIView {
    var am: AMFrameLayout {
        return AMFrameLayout(view: self)
    }
}

@objcMembers
class AMFrameLayout: NSObject, AMLayoutAnchor {
    var view: UIView
    
    init(view: UIView) {
        self.view = view
    }
    
    func make(_ callback: AMFrameLayoutMakerCallback) {
        callback(AMFrameLayoutMaker.init(view: view))
    }
    
}

