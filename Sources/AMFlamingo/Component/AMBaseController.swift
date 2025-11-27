//
//  AMBaseController.swift
//  AMFlamingo
//
//  Created by meotech on 2025/10/20.
//

open class AMBaseController: UIViewController {
    open var needHiddenNavigationBar: Bool {
        return false
    }
    open var isRootControllerInTabbarController: Bool {
        return false
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if needHiddenNavigationBar {
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }
}
