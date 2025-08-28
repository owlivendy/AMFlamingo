//
//  PagePathManager.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/8/8.
//  Copyright © 2025 shen xiaofei. All rights reserved.
//

import UIKit

protocol AMTrackProtocol: NSObjectProtocol {
    func shouldTrackMe() -> Bool
    func trackName() -> String
}

@objcMembers
class AMViewTracker: NSObject {
    let trackName: String
    let title: String?
    
    init(trackName: String, title: String?) {
        self.trackName = trackName
        self.title = title
    }
}

/**
 * 页面路径管理器 - 用于跟踪和管理用户在应用中的页面访问路径
 * 
 * 主要功能：
 * 1. 构建从根视图控制器到当前可见视图控制器的完整导航路径
 * 2. 支持复杂的导航结构：UITabBarController、UINavigationController、模态呈现
 * 3. 为埋点统计提供页面层级上下文信息
 * 4. 过滤只跟踪实现了TrackProtocol且启用跟踪的视图控制器
 * 
 * 使用方法：
 * ```swift
 * // 获取当前可见视图控制器的路径
 * let currentVC = self // 当前视图控制器
 * let pathSegments = PagePathManager.share.pathSegments(for: currentVC)
 * 
 * // pathSegments 包含从根到当前页面的所有可跟踪视图控制器
 * for segment in pathSegments {
 *     print("页面: \(segment.trackName), 标题: \(segment.title ?? "无")")
 * }
 * ```
 * 
 * 设计特点：
 * - 单例模式，确保全局唯一的路径管理实例
 * - 递归算法处理复杂的视图控制器层级结构
 * - 智能避免重复添加容器控制器
 * - 支持模态视图控制器的路径跟踪
 * 
 * 注意事项：
 * - 只有实现 TrackProtocol 且 shouldTrackMe() 返回 true 的视图控制器才会被跟踪
 * - 路径构建会自动处理各种容器控制器，避免重复添加
 * - 如果目标视图控制器不在当前导航栈中，返回空数组
 */
@objcMembers
class AMPagePathManager: NSObject {
    var lastPathSegments = [AMViewTracker]()
    static let share = AMPagePathManager()
    
    func pathSegments(for visibleViewController: UIViewController) -> [AMViewTracker] {
        guard let window = UIApplication.am_keyWindow else {
            return []
        }
        guard let rootVC = window.rootViewController else {
            return []
        }
        
        var found = [UIViewController]()
        _findStack(with: rootVC, target: visibleViewController, stack: &found)
        
        if found.last != visibleViewController, let trackedvc = visibleViewController as? AMTrackProtocol, trackedvc.shouldTrackMe() {
            found.append(visibleViewController)
        }
        
        guard found.last == visibleViewController else {
            return []
        }
        
        return found.compactMap { c in
            if let trackedvc = c as? AMTrackProtocol, trackedvc.shouldTrackMe() {
                return AMViewTracker(trackName: trackedvc.trackName(), title: c.title)
            }
            return nil
        }
    }
    
    /**
     * 查找从根视图控制器到目标视图控制器的完整导航栈路径
     * 
     * 目的：
     * 1. 构建完整的页面层级路径，用于埋点跟踪用户访问轨迹
     * 2. 支持复杂的导航结构：UITabBarController、UINavigationController、模态呈现
     * 3. 确保路径的连续性和准确性，为页面访问统计提供正确的上下文
     * 
     * 实现逻辑：
     * - 递归遍历视图控制器层级结构
     * - 根据不同的容器类型采用不同的处理策略
     * - 避免重复添加已经通过容器管理的视图控制器
     * 
     * @param vc 当前正在处理的视图控制器
     * @param target 目标视图控制器（需要跟踪的当前页面）
     * @param stack 递归构建的导航栈，存储路径上的所有视图控制器
     */
    func _findStack(with vc: UIViewController, target: UIViewController, stack:inout [UIViewController]) {
        if let tabvc = vc as? UITabBarController {
            // 处理 UITabBarController：只跟踪当前选中的标签页
            // 不添加 tabbar 本身到路径中，因为它只是容器
            if let selectedvc = tabvc.selectedViewController {
                _findStack(with: selectedvc, target: target, stack: &stack)
            }
            // 检查是否有模态呈现的视图控制器
            if let presentvc = tabvc.presentedViewController {
                _findStack(with: presentvc, target: target, stack: &stack)
            }
        } else if let navvc = vc as? UINavigationController {
            // 处理 UINavigationController：将导航栈中的所有视图控制器按顺序添加到路径
            // 这样可以反映用户的完整导航历史
            for child in navvc.viewControllers {
                stack.append(child)
                if child == target {
                    return // 找到目标，提前结束递归
                }
            }
            
            // 检查是否有模态呈现的视图控制器（仅当导航控制器不在标签栏中时）
            // 避免重复处理已经被标签栏管理的模态视图
            if let presentvc = navvc.presentedViewController, navvc.tabBarController == nil {
                _findStack(with: presentvc, target: target, stack: &stack)
            }
        } else {
            // 处理普通的 UIViewController
            // 直接添加到路径中，因为它代表一个实际的页面
            stack.append(vc)
            
            // 检查是否有模态呈现的视图控制器
            // 条件：不在标签栏中且不在导航控制器中，避免重复处理
            if let presentvc = vc.presentedViewController, vc.tabBarController == nil, vc.navigationController == nil {
                _findStack(with: presentvc, target: target, stack: &stack)
            }
        }
    }
    
}
