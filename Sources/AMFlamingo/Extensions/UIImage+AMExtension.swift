//
//  UIImage+AMExtension.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/7/22.
//

extension UIImage {
    static func am_Image(named name: String) -> UIImage? {
        #if SWIFT_PACKAGE
        // 在 Swift Package Manager 中，资源文件会被复制到 Bundle.module 中
        return UIImage(named: name, in: .module, compatibleWith: nil)
        #else
        let bundle = Bundle(for: AMFlowlayoutConfig.self)
        if let bundlePath = bundle.path(forResource: "AMFlamingo", ofType: "bundle"),
           let resourceBundle = Bundle(path: bundlePath) {
            return UIImage(named: name, in: resourceBundle, compatibleWith: nil)
        }
        return nil
        #endif
    }
}
