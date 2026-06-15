//
//  AMLeakChildCandidate.swift
//  AMFlamingo
//

import UIKit

@objc public enum AMLeakChildAssociationType: Int {
    case addChild = 0
    case property
    case viewInference
    case manualRegister
}

@objc(AMLeakChildCandidate)
@objcMembers
public final class AMLeakChildCandidate: NSObject {

    public weak var viewController: UIViewController?
    public var className: String = ""
    public var associationType: AMLeakChildAssociationType = .addChild
    /// 如 property 名、addChild 说明等
    public var associationDetail: String?

    @objc(displayNameForAssociationType:)
    public static func displayName(for type: AMLeakChildAssociationType) -> String {
        switch type {
        case .addChild: return "addChildViewController"
        case .property: return "property"
        case .viewInference: return "inferredFromView"
        case .manualRegister: return "manualRegister"
        }
    }

    public func associationDescription() -> String {
        let typeName = Self.displayName(for: associationType)
        if associationType == .property, let detail = associationDetail, !detail.isEmpty {
            return "\(typeName):\(detail)"
        }
        if let detail = associationDetail, !detail.isEmpty {
            return "\(typeName) (\(detail))"
        }
        return typeName
    }
}
