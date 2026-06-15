//
//  AMLeakFinderEngine.swift
//  AMFlamingo
//
//  DEBUG-only leak detection engine.
//

#if DEBUG

import ObjectiveC
import UIKit

enum AMLeakFinderEngine {

    static var isRunning = false
    static var checkDelay: TimeInterval = 2.0
    static var includedClassPrefixes: [String]?
    private static var swizzled = false
    private static var snapshots: NSMapTable<UIViewController, AMLeakSnapshot>!
    private static var snapshotAssociationKey: UInt8 = 0

    // MARK: - Lifecycle

    static func start() {
        DispatchQueue.once(token: "com.flamingo.AMLeakFinder.start") {
            snapshots = NSMapTable<UIViewController, AMLeakSnapshot>(
                keyOptions: .weakMemory,
                valueOptions: .strongMemory
            )
            installSwizzles()
        }
        isRunning = true
    }

    static func stop() {
        isRunning = false
    }

    static func registerChildViewController(_ child: UIViewController, forParent parent: UIViewController) {
        guard isRunning, shouldTrackViewController(child) else { return }
        guard let snapshot = activeSnapshot(for: parent) else { return }
        snapshot.addCandidateChildViewController(
            child,
            associationType: .manualRegister,
            associationDetail: nil
        )
    }

    // MARK: - Swizzling

    private static func installSwizzles() {
        guard !swizzled else { return }
        swizzled = true

        swizzle(UIViewController.self, #selector(UIViewController.present(_:animated:completion:)), #selector(UIViewController.amlf_present(_:animated:completion:)))
        swizzle(UIViewController.self, #selector(UIViewController.dismiss(animated:completion:)), #selector(UIViewController.amlf_dismiss(animated:completion:)))
        swizzle(UIViewController.self, #selector(UIViewController.addChild(_:)), #selector(UIViewController.amlf_addChild(_:)))

        swizzle(UINavigationController.self, #selector(UINavigationController.pushViewController(_:animated:)), #selector(UINavigationController.amlf_pushViewController(_:animated:)))
        swizzle(UINavigationController.self, #selector(UINavigationController.setViewControllers(_:animated:)), #selector(UINavigationController.amlf_setViewControllers(_:animated:)))
        swizzle(UINavigationController.self, #selector(UINavigationController.popViewController(animated:)), #selector(UINavigationController.amlf_popViewController(animated:)))
        swizzle(UINavigationController.self, #selector(UINavigationController.popToViewController(_:animated:)), #selector(UINavigationController.amlf_popToViewController(_:animated:)))
        swizzle(UINavigationController.self, #selector(UINavigationController.popToRootViewController(animated:)), #selector(UINavigationController.amlf_popToRootViewController(animated:)))

        swizzle(UIView.self, #selector(UIView.addSubview(_:)), #selector(UIView.amlf_addSubview(_:)))
        swizzle(UIView.self, #selector(UIView.insertSubview(_:at:)), #selector(UIView.amlf_insertSubview(_:at:)))
        swizzle(UIView.self, #selector(UIView.insertSubview(_:belowSubview:)), #selector(UIView.amlf_insertSubview(_:belowSubview:)))
        swizzle(UIView.self, #selector(UIView.insertSubview(_:aboveSubview:)), #selector(UIView.amlf_insertSubview(_:aboveSubview:)))
    }

    private static func swizzle(_ cls: AnyClass, _ original: Selector, _ swizzled: Selector) {
        guard let originalMethod = class_getInstanceMethod(cls, original),
              let swizzledMethod = class_getInstanceMethod(cls, swizzled) else { return }
        if class_addMethod(cls, original, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod)) {
            class_replaceMethod(cls, swizzled, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }

    // MARK: - Tracking

    static func shouldTrackViewController(_ viewController: UIViewController?) -> Bool {
        guard let viewController, isRunning else { return false }
        let className = String(describing: type(of: viewController))
        if isSystemViewControllerClassName(className) { return false }

        if let prefixes = includedClassPrefixes, !prefixes.isEmpty {
            let matched = prefixes.contains { !$0.isEmpty && className.hasPrefix($0) }
            if !matched { return false }
        }
        return true
    }

    private static func isSystemViewControllerClassName(_ className: String) -> Bool {
        let blacklist: Set<String> = [
            "UINavigationController", "UITabBarController", "UISplitViewController",
            "UIPageViewController", "UIAlertController", "UIActivityViewController",
            "UIImagePickerController", "UIDocumentPickerViewController",
            "UIInputWindowController", "UIEditingOverlayViewController",
            "UISystemKeyboard", "UICompatibilityInputViewController",
        ]
        if blacklist.contains(className) { return true }
        if className.hasPrefix("_") { return true }
        if className.hasPrefix("UI") && !className.hasPrefix("UIHosting") { return true }
        return false
    }

    static func beginTrackingViewController(_ viewController: UIViewController) {
        guard shouldTrackViewController(viewController) else { return }
        if associatedSnapshot(for: viewController) != nil { return }

        let snapshot = AMLeakSnapshot()
        snapshot.viewController = viewController
        snapshot.viewControllerClassName = String(describing: type(of: viewController))
        snapshot.syncPreloadedSubviews(for: viewController)
        setAssociatedSnapshot(snapshot, for: viewController)
        snapshots.setObject(snapshot, forKey: viewController)
    }

    static func beginTrackingPushedOrPresentedViewController(_ viewController: UIViewController) {
        if let nav = viewController as? UINavigationController {
            nav.viewControllers.forEach { beginTrackingViewController($0) }
            return
        }
        if let tab = viewController as? UITabBarController {
            tab.viewControllers?.forEach { beginTrackingViewController($0) }
            return
        }
        beginTrackingViewController(viewController)
    }

    static func scheduleLeakCheckForViewControllerIncludingChildren(_ viewController: UIViewController) {
        scheduleLeakCheck(for: viewController)
    }

    static func scheduleLeakCheckForViewControllers(_ viewControllers: [UIViewController]) {
        viewControllers.forEach { scheduleLeakCheckForViewControllerIncludingChildren($0) }
    }

    private static func scheduleLeakCheck(for viewController: UIViewController) {
        guard isRunning else { return }
        var snapshot = associatedSnapshot(for: viewController)
        if snapshot == nil {
            snapshot = snapshots.object(forKey: viewController)
        }
        guard let snapshot else { return }

        collectCandidateChildViewControllers(for: snapshot, from: viewController)
        setAssociatedSnapshot(nil, for: viewController)
        snapshots.removeObject(forKey: viewController)

        let className = snapshot.viewControllerClassName
        let delay = checkDelay
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard isRunning else { return }
            performLeakCheck(snapshot: snapshot, viewControllerClassName: className)
        }
    }

    static func activeSnapshot(for viewController: UIViewController) -> AMLeakSnapshot? {
        if let snapshot = associatedSnapshot(for: viewController) { return snapshot }
        return snapshots.object(forKey: viewController)
    }

    static func trackAddedSubview(_ subview: UIView, onContainer container: UIView) {
        guard isRunning else { return }

        if container is UIWindow {
            guard let topVC = topmostTrackableViewController(),
                  shouldTrackViewController(topVC),
                  let snapshot = activeSnapshot(for: topVC) else { return }
            snapshot.trackWindowSubview(subview)
            return
        }

        let enumerator = snapshots.keyEnumerator()
        while let vc = enumerator.nextObject() as? UIViewController {
            guard shouldTrackViewController(vc), vc.isViewLoaded, let root = vc.view else { continue }
            guard isView(container, equalToOrDescendantOf: root) else { continue }
            activeSnapshot(for: vc)?.trackSubview(subview)
        }
    }

    // MARK: - Leak Check

    private static func performLeakCheck(snapshot: AMLeakSnapshot, viewControllerClassName className: String) {
        if let vc = snapshot.viewController {
            reportViewControllerLeak(className: className, pointer: vc)
            return
        }

        var leakedChildren: [AMLeakChildCandidate] = []
        var leakedChildVCSet = Set<UIViewController>()
        for case let candidate as AMLeakChildCandidate in snapshot.candidateChildViewControllers {
            guard let childVC = candidate.viewController, shouldTrackViewController(childVC) else { continue }
            leakedChildren.append(candidate)
            leakedChildVCSet.insert(childVC)
        }

        var orphanViews: [UIView] = []
        collectOrphanLeakedViews(from: snapshot, leakedChildVCSet: leakedChildVCSet, into: &orphanViews)

        guard !leakedChildren.isEmpty || !orphanViews.isEmpty else { return }

        var body = ""
        if !leakedChildren.isEmpty {
            body += "[UIViewController] \(className) 已释放，但子控制器未被释放:\n"
            for candidate in leakedChildren {
                let pointer: String
                if let vc = candidate.viewController {
                    pointer = String(describing: Unmanaged.passUnretained(vc).toOpaque())
                } else {
                    pointer = "nil"
                }
                body += "- \(candidate.className) (\(pointer))\n"
                body += "  关联方式: \(candidate.associationDescription())\n"
            }
        }
        if !orphanViews.isEmpty {
            if !body.isEmpty { body += "\n" }
            body += "[UIView] 孤立视图未被释放（所属页面 \(className) 已释放）:\n"
            for view in orphanViews {
                body += "- \(String(describing: type(of: view))) (\(Unmanaged.passUnretained(view).toOpaque()))\n"
                body += hierarchyDescription(for: view)
            }
        }
        printLeakReport(body)
    }

    private static func reportViewControllerLeak(className: String, pointer: UIViewController) {
        var body = "[UIViewController] \(className) 未被释放 (\(Unmanaged.passUnretained(pointer).toOpaque()))\n"
        printLeakReport(body)
    }

    private static func hierarchyDescription(for view: UIView) -> String {
        var result = "  层级:\n"
        var current: UIView? = view
        var depth = 0
        while let node = current, depth < 20 {
            let indent = String(repeating: " ", count: 2 + depth * 2)
            result += "\(indent)\(String(describing: type(of: node))) (\(Unmanaged.passUnretained(node).toOpaque()))\n"
            current = node.superview
            depth += 1
        }
        return result
    }

    private static func printLeakReport(_ body: String) {
        NSLog("\n******** 监测到内存泄露 *****************\n\n%@\n\n**************************************\n", body)
    }

    // MARK: - Candidate Collection

    static func collectCandidateChildViewControllersRecursively(
        from viewController: UIViewController,
        snapshot: AMLeakSnapshot,
        seen: inout Set<UIViewController>
    ) {
        guard !seen.contains(viewController) else { return }
        seen.insert(viewController)

        for child in viewController.children {
            guard !shouldExcludePropertyChild(child, relativeTo: viewController) else { continue }
            snapshot.addCandidateChildViewController(
                child,
                associationType: .addChild,
                associationDetail: "childViewControllers"
            )
            collectCandidateChildViewControllersRecursively(from: child, snapshot: snapshot, seen: &seen)
        }

        collectViewControllersFromProperties(of: viewController, parentVC: viewController, snapshot: snapshot, seen: &seen)
    }

    private static func collectCandidateChildViewControllers(for snapshot: AMLeakSnapshot, from parent: UIViewController) {
        var seen: Set<UIViewController> = [parent]
        for child in parent.children {
            guard !shouldExcludePropertyChild(child, relativeTo: parent) else { continue }
            snapshot.addCandidateChildViewController(
                child,
                associationType: .addChild,
                associationDetail: "childViewControllers"
            )
            collectCandidateChildViewControllersRecursively(from: child, snapshot: snapshot, seen: &seen)
        }
        collectViewControllersFromProperties(of: parent, parentVC: parent, snapshot: snapshot, seen: &seen)
        collectCandidateChildrenInferredFromViews(for: snapshot, parentVC: parent, seen: &seen)
    }

    private static func collectCandidateChildrenInferredFromViews(
        for snapshot: AMLeakSnapshot,
        parentVC parent: UIViewController,
        seen: inout Set<UIViewController>
    ) {
        var allViews = Set<UIView>()
        snapshot.trackedViews.allObjects.forEach { allViews.insert($0) }
        snapshot.windowAddedObjects.allObjects.forEach { allViews.insert($0) }

        for view in allViews {
            guard let owner = viewController(for: view),
                  owner !== parent,
                  !seen.contains(owner),
                  !shouldExcludePropertyChild(owner, relativeTo: parent) else { continue }
            seen.insert(owner)
            snapshot.addCandidateChildViewController(
                owner,
                associationType: .viewInference,
                associationDetail: String(describing: type(of: view))
            )
            collectCandidateChildViewControllersRecursively(from: owner, snapshot: snapshot, seen: &seen)
        }
    }

    private static func collectViewControllersFromProperties(
        of object: AnyObject,
        parentVC parent: UIViewController,
        snapshot: AMLeakSnapshot,
        seen: inout Set<UIViewController>
    ) {
        var cls: AnyClass? = object_getClass(object)
        while let current = cls, current != NSObject.self {
            var propertyCount: UInt32 = 0
            if let properties = class_copyPropertyList(current, &propertyCount) {
                defer { free(properties) }
                for i in 0..<Int(propertyCount) {
                    let property = properties[i]
                    let nameC = property_getName(property)
                    guard let attributesC = property_getAttributes(property) else { continue }
                    let attributes = String(cString: attributesC)
                    let propertyType = propertyTypeFromAttributes(attributes)
                    guard typeEncodingIsViewController(attributes) || propertyType.contains("ViewController") else { continue }

                    let propertyName = String(cString: nameC)
                    let getter = NSSelectorFromString(propertyName)
                    guard object.responds(to: getter),
                          let value = object.perform(getter)?.takeUnretainedValue() as? UIViewController,
                          !shouldExcludePropertyChild(value, relativeTo: parent) else { continue }

                    snapshot.addCandidateChildViewController(
                        value,
                        associationType: .property,
                        associationDetail: propertyName
                    )
                    collectCandidateChildViewControllersRecursively(from: value, snapshot: snapshot, seen: &seen)
                }
            }

            var ivarCount: UInt32 = 0
            if let ivars = class_copyIvarList(current, &ivarCount) {
                defer { free(ivars) }
                for i in 0..<Int(ivarCount) {
                    let ivar = ivars[i]
                    guard let encodingC = ivar_getTypeEncoding(ivar),
                          typeEncodingIsViewController(String(cString: encodingC)),
                          let value = object_getIvar(object, ivar) as? UIViewController,
                          !shouldExcludePropertyChild(value, relativeTo: parent) else { continue }

                    let ivarName = String(cString: ivar_getName(ivar)!)
                    snapshot.addCandidateChildViewController(
                        value,
                        associationType: .property,
                        associationDetail: ivarName
                    )
                    collectCandidateChildViewControllersRecursively(from: value, snapshot: snapshot, seen: &seen)
                }
            }

            cls = class_getSuperclass(current)
        }
    }

    private static func shouldExcludePropertyChild(_ child: UIViewController?, relativeTo parent: UIViewController) -> Bool {
        guard let child, child !== parent else { return true }
        if child === parent.navigationController ||
            child === parent.tabBarController ||
            child === parent.presentedViewController ||
            child === parent.presentingViewController {
            return true
        }
        return !shouldTrackViewController(child)
    }

    private static func typeEncodingIsViewController(_ typeEncoding: String) -> Bool {
        guard typeEncoding.first == "@" else { return false }
        return typeEncoding.contains("ViewController")
    }

    private static func propertyTypeFromAttributes(_ attributes: String) -> String {
        guard let typeRange = attributes.range(of: "T") else { return "" }
        let remainder = attributes[typeRange.upperBound...]
        guard remainder.hasPrefix("@\"") else { return "" }
        let start = remainder.index(remainder.startIndex, offsetBy: 2)
        guard let end = remainder[start...].firstIndex(of: "\"") else { return "" }
        return String(remainder[start..<end])
    }

    private static func viewController(for view: UIView) -> UIViewController? {
        var responder: UIResponder? = view
        while let current = responder {
            if let vc = current as? UIViewController { return vc }
            responder = current.next
        }
        return nil
    }

    private static func collectOrphanLeakedViews(
        from snapshot: AMLeakSnapshot,
        leakedChildVCSet: Set<UIViewController>,
        into orphanViews: inout [UIView]
    ) {
        var added = Set<UIView>()
        let tables = [snapshot.trackedViews, snapshot.windowAddedObjects]
        for table in tables {
            for view in table.allObjects {
                guard !added.contains(view) else { continue }
                if let owner = viewController(for: view) {
                    if leakedChildVCSet.contains(owner) { continue }
                    if shouldTrackViewController(owner) { continue }
                }
                orphanViews.append(view)
                added.insert(view)
            }
        }
    }

    // MARK: - Top VC

    private static func topmostTrackableViewController() -> UIViewController? {
        var window: UIWindow?
        if #available(iOS 13.0, *) {
            for scene in UIApplication.shared.connectedScenes {
                guard scene.activationState == .foregroundActive,
                      let windowScene = scene as? UIWindowScene else { continue }
                if let key = windowScene.windows.first(where: { $0.isKeyWindow }) {
                    window = key
                    break
                }
            }
        }
        if window == nil {
            window = UIApplication.am_keyWindow
        }
        return topmostViewController(from: window?.rootViewController)
    }

    private static func topmostViewController(from root: UIViewController?) -> UIViewController? {
        guard var current = root else { return nil }
        while let presented = current.presentedViewController {
            current = presented
        }
        if let nav = current as? UINavigationController {
            current = nav.topViewController ?? current
        }
        if let tab = current as? UITabBarController, let selected = tab.selectedViewController {
            current = topmostViewController(from: selected) ?? current
        }
        return current
    }

    private static func isView(_ view: UIView, equalToOrDescendantOf ancestor: UIView) -> Bool {
        var current: UIView? = view
        while let node = current {
            if node === ancestor { return true }
            current = node.superview
        }
        return false
    }

    // MARK: - Associated Object

    private static func associatedSnapshot(for viewController: UIViewController) -> AMLeakSnapshot? {
        objc_getAssociatedObject(viewController, &snapshotAssociationKey) as? AMLeakSnapshot
    }

    private static func setAssociatedSnapshot(_ snapshot: AMLeakSnapshot?, for viewController: UIViewController) {
        objc_setAssociatedObject(
            viewController,
            &snapshotAssociationKey,
            snapshot,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
}

// MARK: - DispatchQueue once

private extension DispatchQueue {
    private static var _onceTokens: [String: Bool] = [:]
    private static let onceLock = NSLock()

    static func once(token: String = #function, block: () -> Void) {
        onceLock.lock()
        defer { onceLock.unlock() }
        guard _onceTokens[token] != true else { return }
        _onceTokens[token] = true
        block()
    }
}

#endif
