//
//  NSObject+Extension.swift
//  ChinaHomelife247
//
//  Created by meotech on 2025/8/13.
//  Copyright © 2025 吕欢. All rights reserved.
//

import Foundation

public extension NSObject {
    static var className: String {
        get {
            return NSStringFromClass(self.classForCoder())
        }
    }
}
