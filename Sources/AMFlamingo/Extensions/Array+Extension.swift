//
//  Array+Extension.swift
//  ChinaHomelife247
//
//  Created by meotech on 2025/11/11.
//  Copyright © 2025 吕欢. All rights reserved.
//

import Foundation

public extension Array {
    //实现扩展方法，根据block 返回移除的第一个元素
    mutating func removeFirst(where block: (Element) -> Bool) {
        if let index = self.firstIndex(where: block) {
            self.remove(at: index)
        }
    }
}
