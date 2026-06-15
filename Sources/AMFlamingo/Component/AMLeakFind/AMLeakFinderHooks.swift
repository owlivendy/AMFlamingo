//
//  AMLeakFinderHooks.swift
//  AMFlamingo
//

#if DEBUG

import UIKit

extension UIViewController {

    @objc func amlf_present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        amlf_present(viewControllerToPresent, animated: flag, completion: completion)
        AMLeakFinderEngine.beginTrackingPushedOrPresentedViewController(viewControllerToPresent)
    }

    @objc func amlf_addChild(_ childController: UIViewController) {
        amlf_addChild(childController)
        guard let snapshot = AMLeakFinderEngine.activeSnapshot(for: self) else { return }
        snapshot.addCandidateChildViewController(
            childController,
            associationType: .addChild,
            associationDetail: "addChildViewController"
        )
        var seen: Set<UIViewController> = [self]
        AMLeakFinderEngine.collectCandidateChildViewControllersRecursively(
            from: childController,
            snapshot: snapshot,
            seen: &seen
        )
    }

    @objc func amlf_dismiss(animated flag: Bool, completion: (() -> Void)?) {
        var dismissedVC: UIViewController?
        if let presented = presentedViewController {
            dismissedVC = presented
        } else if presentingViewController != nil {
            dismissedVC = self
        }
        amlf_dismiss(animated: flag, completion: completion)
        if let dismissedVC {
            AMLeakFinderEngine.scheduleLeakCheckForViewControllerIncludingChildren(dismissedVC)
        }
    }
}

extension UINavigationController {

    @objc func amlf_pushViewController(_ viewController: UIViewController, animated: Bool) {
        amlf_pushViewController(viewController, animated: animated)
        AMLeakFinderEngine.beginTrackingViewController(viewController)
    }

    @objc func amlf_setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        amlf_setViewControllers(viewControllers, animated: animated)
        viewControllers.forEach { AMLeakFinderEngine.beginTrackingViewController($0) }
    }

    @objc func amlf_popViewController(animated: Bool) -> UIViewController? {
        let popped = amlf_popViewController(animated: animated)
        if let popped {
            AMLeakFinderEngine.scheduleLeakCheckForViewControllerIncludingChildren(popped)
        }
        return popped
    }

    @objc func amlf_popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        let stack = viewControllers
        var poppedVCs: [UIViewController] = []
        if let targetIndex = stack.firstIndex(of: viewController), targetIndex + 1 < stack.count {
            poppedVCs = Array(stack[(targetIndex + 1)...])
        }
        let result = amlf_popToViewController(viewController, animated: animated)
        AMLeakFinderEngine.scheduleLeakCheckForViewControllers(poppedVCs)
        return result
    }

    @objc func amlf_popToRootViewController(animated: Bool) -> [UIViewController]? {
        let stack = viewControllers
        var poppedVCs: [UIViewController] = []
        if stack.count > 1 {
            poppedVCs = Array(stack[1...])
        }
        let result = amlf_popToRootViewController(animated: animated)
        AMLeakFinderEngine.scheduleLeakCheckForViewControllers(poppedVCs)
        return result
    }
}

extension UIView {

    @objc func amlf_addSubview(_ view: UIView) {
        amlf_addSubview(view)
        AMLeakFinderEngine.trackAddedSubview(view, onContainer: self)
    }

    @objc func amlf_insertSubview(_ view: UIView, at index: Int) {
        amlf_insertSubview(view, at: index)
        AMLeakFinderEngine.trackAddedSubview(view, onContainer: self)
    }

    @objc func amlf_insertSubview(_ view: UIView, belowSubview siblingSubview: UIView) {
        amlf_insertSubview(view, belowSubview: siblingSubview)
        AMLeakFinderEngine.trackAddedSubview(view, onContainer: self)
    }

    @objc func amlf_insertSubview(_ view: UIView, aboveSubview siblingSubview: UIView) {
        amlf_insertSubview(view, aboveSubview: siblingSubview)
        AMLeakFinderEngine.trackAddedSubview(view, onContainer: self)
    }
}

#endif
