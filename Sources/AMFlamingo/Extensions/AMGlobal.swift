//
//  Global.swift
//  AMFlamingo
//
//  Created by meotech on 2025/9/28.
//

import Foundation

class AMGlobal {
    static func performOnMainThread(exe:@escaping ()->(Void)) {
        if Thread.isMainThread {
            exe()
        } else {
            DispatchQueue.main.async {
                exe()
            }
        }
    }
}



