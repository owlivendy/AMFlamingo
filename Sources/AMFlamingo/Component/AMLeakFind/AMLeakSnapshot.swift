//
//  AMLeakSnapshot.swift
//  AMFlamingo
//

import UIKit

final class AMLeakSnapshot: NSObject {

    var viewControllerClassName: String = ""
    weak var viewController: UIViewController?
    let trackedViews = NSHashTable<UIView>.weakObjects()
    let windowAddedObjects = NSHashTable<UIView>.weakObjects()
    let candidateChildViewControllers = NSMutableArray()

    func syncPreloadedSubviews(for viewController: UIViewController) {
        guard viewController.isViewLoaded, let rootView = viewController.view else { return }
        trackSubview(rootView)
        syncPreloadedSubviews(under: rootView)
    }

    private func syncPreloadedSubviews(under view: UIView) {
        for subview in view.subviews {
            trackSubview(subview)
            syncPreloadedSubviews(under: subview)
        }
    }

    func trackSubview(_ view: UIView?) {
        guard let view, !shouldIgnoreView(view) else { return }
        trackedViews.add(view)
    }

    func trackWindowSubview(_ view: UIView?) {
        guard let view, !shouldIgnoreView(view) else { return }
        windowAddedObjects.add(view)
    }

    func addCandidateChildViewController(
        _ child: UIViewController?,
        associationType: AMLeakChildAssociationType,
        associationDetail detail: String?
    ) {
        guard let child else { return }

        for case let existing as AMLeakChildCandidate in candidateChildViewControllers {
            if existing.viewController === child {
                if associationType.rawValue > existing.associationType.rawValue {
                    existing.associationType = associationType
                }
                if let detail, !detail.isEmpty {
                    if let existingDetail = existing.associationDetail, !existingDetail.isEmpty {
                        if !existingDetail.contains(detail) {
                            existing.associationDetail = "\(existingDetail), \(detail)"
                        }
                    } else {
                        existing.associationDetail = detail
                    }
                }
                return
            }
        }

        let candidate = AMLeakChildCandidate()
        candidate.viewController = child
        candidate.className = String(describing: type(of: child))
        candidate.associationType = associationType
        candidate.associationDetail = detail
        candidateChildViewControllers.add(candidate)
    }

    private func shouldIgnoreView(_ view: UIView) -> Bool {
        let className = String(describing: type(of: view))
        if className.hasPrefix("_") { return true }

        let ignoredPrefixes = [
            "UILayout", "UIDrop", "UITransition", "UIShadow", "UIKeyboard",
            "UIInput", "UICallout", "UIRemote", "UIStatusBar", "UINavigationBar",
            "UITabBar", "UIToolbar", "UIWindow",
        ]
        return ignoredPrefixes.contains { className.hasPrefix($0) }
    }
}
