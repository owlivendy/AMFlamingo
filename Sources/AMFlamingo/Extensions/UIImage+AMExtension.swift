//
//  UIImage+AMExtension.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/7/22.
//

public extension UIImage {
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
    
    /// 图片缩放为指定最大尺寸的缩略图（保持宽高比）
    /// - Parameter maxSize: 缩略图最大尺寸（如200x200）
    /// - Returns: 缩放后的缩略图
    func scaledToThumbnailSize(maxSize: CGSize) -> UIImage {
        let widthRatio = maxSize.width / size.width
        let heightRatio = maxSize.height / size.height
        let scaleRatio = min(widthRatio, heightRatio) // 取较小比例，避免超出最大尺寸
        
        let scaledSize = CGSize(width: size.width * scaleRatio, height: size.height * scaleRatio)
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        
        return renderer.image { context in
            draw(in: CGRect(origin: .zero, size: scaledSize))
        }
    }
}
