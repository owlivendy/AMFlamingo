//
//  AMBaseController.swift
//  AMFlamingo
//
//  Created by meotech on 2025/10/20.
//

class AMBaseController: UIViewController {
    var needHiddenNavigationBar: Bool {
        return false
    }
    var isRootControllerInTabbarController: Bool {
        return false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if needHiddenNavigationBar {
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }
}
