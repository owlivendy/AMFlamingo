//
//  AMFrameLayout.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/7/2.
//  Copyright © 2025 shen xiaofei. All rights reserved.
//


public typealias AMFrameLayoutMakerCallback = ((AMFrameLayoutMaker)->(Void))

public extension UIView {
    var am: AMFrameLayout {
        return AMFrameLayout(view: self)
    }
}

@objcMembers
public class AMFrameLayout: NSObject, AMLayoutAnchor {
    public var view: UIView
    
    public init(view: UIView) {
        self.view = view
    }
    
    public func make(_ callback: AMFrameLayoutMakerCallback) {
        callback(AMFrameLayoutMaker.init(view: view))
    }
    
}

