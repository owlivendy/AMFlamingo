//
//  AMLayoutAnchor.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/8/21.
//  Copyright © 2025 shen xiaofei. All rights reserved.
//

public protocol AMLayoutAnchor {
    
    var left: AMFrameLayoutAnchor { get }
    var right: AMFrameLayoutAnchor { get }
    var top: AMFrameLayoutAnchor { get }
    var bottom: AMFrameLayoutAnchor { get }
    var centerX: AMFrameLayoutAnchor { get }
    var centerY: AMFrameLayoutAnchor { get }
    var leading: AMFrameLayoutAnchor { get }
    var trailing: AMFrameLayoutAnchor { get }
    var size: AMFrameLayoutAnchor { get }
    var view: UIView { get }
    
}

public extension AMLayoutAnchor {
    var left: AMFrameLayoutAnchor {
        return AMFrameLayoutAnchor(view: view, type: .left)
    }
    var right: AMFrameLayoutAnchor {
        return AMFrameLayoutAnchor(view: view, type: .right)
    }
    var top: AMFrameLayoutAnchor {
        return AMFrameLayoutAnchor(view: view, type: .top)
    }
    var bottom: AMFrameLayoutAnchor {
        return AMFrameLayoutAnchor(view: view, type: .bottom)
    }
    var centerX: AMFrameLayoutAnchor {
        return AMFrameLayoutAnchor(view: view, type: .centerX)
    }
    var centerY: AMFrameLayoutAnchor {
        return AMFrameLayoutAnchor(view: view, type: .centerY)
    }
    var leading: AMFrameLayoutAnchor {
        return AMFrameLayoutAnchor(view: view, type: .leading)
    }
    var trailing: AMFrameLayoutAnchor {
        return AMFrameLayoutAnchor(view: view, type: .trailing)
    }
    var size: AMFrameLayoutAnchor {
        return AMFrameLayoutAnchor(view: view, type: .size)
    }
}
