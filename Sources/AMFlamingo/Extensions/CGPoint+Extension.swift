//
//  CGPoint+Extension.swift
//  ChinaHomelife247
//
//  Created by meotech on 2025/11/12.
//  Copyright © 2025 吕欢. All rights reserved.
//

import Foundation

public extension CGPoint {
    func offset(x: CGFloat) -> CGPoint {
        return CGPoint(x: self.x + x, y: self.y)
    }
    
    func offset(y: CGFloat) -> CGPoint {
        return CGPoint(x: self.x, y: self.y + y)
    }
    
    func offset(x: CGFloat, y: CGFloat) -> CGPoint {
        return CGPoint(x: self.x + x, y: self.y + y)
    }
}
