//
//  AMLeakFinder.swift
//  AMFlamingo
//
//  内存泄漏监测（仅 DEBUG 编译有效，Release 为空实现）
//

import Foundation
import UIKit

@objc(AMLeakFinder)
@objcMembers
public final class AMLeakFinder: NSObject {

    private override init() {
        super.init()
    }

    public static var isRunning: Bool {
        #if DEBUG
        return AMLeakFinderEngine.isRunning
        #else
        return false
        #endif
    }

    public static var checkDelay: TimeInterval {
        get {
            #if DEBUG
            return AMLeakFinderEngine.checkDelay
            #else
            return 2.0
            #endif
        }
        set {
            #if DEBUG
            AMLeakFinderEngine.checkDelay = newValue > 0 ? newValue : 2.0
            #endif
        }
    }

    
    /// 不设置默认检测系统以外的所有 自定义  UIView 和 UIViewController 的子类
    public static var includedClassPrefixes: [String] {
        get {
            #if DEBUG
            return AMLeakFinderEngine.includedClassPrefixes ?? []
            #else
            return []
            #endif
        }
        set {
            #if DEBUG
            AMLeakFinderEngine.includedClassPrefixes = newValue
            #endif
        }
    }

    public static func start() {
        #if DEBUG
        AMLeakFinderEngine.start()
        #endif
    }

    public static func stop() {
        #if DEBUG
        AMLeakFinderEngine.stop()
        #endif
    }

    /// 手动登记：父 VC 强引用子 VC，但未 addChild / 属性扫描不到（如 Swift 私有属性）
    @objc(registerChildViewController:forParent:)
    public static func registerChildViewController(_ child: UIViewController, forParent parent: UIViewController) {
        #if DEBUG
        AMLeakFinderEngine.registerChildViewController(child, forParent: parent)
        #endif
    }
}
