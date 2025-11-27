//
//  AMBaseNavigationController.swift
//  AMFlamingo
//
//  Created by meotech on 2025/10/20.
//

open class AMBaseNavigationController: UINavigationController {
    open override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        // 导航栏显示逻辑
        if let current = viewControllers.last {
            // 处理根视图控制器在 TabBar 中的情况
            if viewControllers.count == 1 {
                if let rootvc = viewControllers.first as? AMBaseController {
                    if rootvc.isRootControllerInTabbarController {
                        viewController.hidesBottomBarWhenPushed = true
                    }
                }
            }
            
            super.pushViewController(viewController, animated: animated)
            
            // 处理当前控制器的导航栏隐藏逻辑
            if let basevc = current as? AMBaseController {
                if basevc.needHiddenNavigationBar {
                    basevc.navigationController?.setNavigationBarHidden(false, animated: true)
                }
            }
        } else {
            // 若当前无栈顶控制器，直接调用父类方法
            super.pushViewController(viewController, animated: animated)
        }
    }
}
