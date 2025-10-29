import UIKit

public extension UIImage {
    
    enum AMImageContentMode {
        case aspectFill
        case scaleFill
        case aspectFit
    }
    
    /// 将图片按预览层的遮罩留白矩形进行裁剪
    /// - Parameters:
    ///   - containerSize: 容器尺寸（例如预览层尺寸，单位 point）
    ///   - overlayRect: 未遮罩区域矩形（单位 point，在容器坐标系中）
    ///   - contentMode: 内容填充模式（aspectFill/scaleFill/aspectFit）
    /// - Returns: 裁剪后的新图片（方向为 .up），若失败则返回原图或 nil
    func am_crop(containerSize: CGSize, overlayRect: CGRect, contentMode: AMImageContentMode) -> UIImage? {
        let uprightImage = self.am_fixedOrientationUp()
        guard let cg = uprightImage.cgImage else { return nil }
    
        let pixelSize = CGSize(width: CGFloat(cg.width), height: CGFloat(cg.height))
        if pixelSize.width <= 0 || pixelSize.height <= 0 { return self }
    
        // 计算 point -> pixel 的缩放与偏移
        var cropRect: CGRect
        switch contentMode {
        case .aspectFill:
            // 修正：AspectFill 应使用 min(P/C) 作为 point->pixel 的比例
            let scale = min(pixelSize.width / containerSize.width, pixelSize.height / containerSize.height)
            let displayedSize = CGSize(width: containerSize.width * scale, height: containerSize.height * scale)
            let xOffset = (pixelSize.width - displayedSize.width) * 0.5
            let yOffset = (pixelSize.height - displayedSize.height) * 0.5
            cropRect = CGRect(x: overlayRect.origin.x * scale + xOffset,
                              y: overlayRect.origin.y * scale + yOffset,
                              width: overlayRect.size.width * scale,
                              height: overlayRect.size.height * scale)
        case .scaleFill:
            let scaleX = pixelSize.width / containerSize.width
            let scaleY = pixelSize.height / containerSize.height
            cropRect = CGRect(x: overlayRect.origin.x * scaleX,
                              y: overlayRect.origin.y * scaleY,
                              width: overlayRect.size.width * scaleX,
                              height: overlayRect.size.height * scaleY)
        case .aspectFit:
            // 修正：AspectFit 应使用 max(P/C) 作为 point->pixel 的比例
            let scale = max(pixelSize.width / containerSize.width, pixelSize.height / containerSize.height)
            let displayedSize = CGSize(width: containerSize.width * scale, height: containerSize.height * scale)
            let xOffset = (pixelSize.width - displayedSize.width) * 0.5
            let yOffset = (pixelSize.height - displayedSize.height) * 0.5
            cropRect = CGRect(x: overlayRect.origin.x * scale + xOffset,
                              y: overlayRect.origin.y * scale + yOffset,
                              width: overlayRect.size.width * scale,
                              height: overlayRect.size.height * scale)
        }
    
        cropRect = cropRect.integral
    
        let imageBounds = CGRect(x: 0, y: 0, width: pixelSize.width, height: pixelSize.height)
        cropRect = cropRect.intersection(imageBounds)
        guard cropRect.width > 0, cropRect.height > 0 else {
            // 回退：保持与取景框相同的长宽比，居中裁剪
            let targetAspect = overlayRect.size.width / overlayRect.size.height
            let srcAspect = pixelSize.width / pixelSize.height
            var fallbackRect = imageBounds
            if srcAspect > targetAspect {
                let newWidth = pixelSize.height * targetAspect
                let x = (pixelSize.width - newWidth) * 0.5
                fallbackRect = CGRect(x: x, y: 0, width: newWidth, height: pixelSize.height)
            } else {
                let newHeight = pixelSize.width / targetAspect
                let y = (pixelSize.height - newHeight) * 0.5
                fallbackRect = CGRect(x: 0, y: y, width: pixelSize.width, height: newHeight)
            }
            if let fbCG = cg.cropping(to: fallbackRect.integral) {
                return UIImage(cgImage: fbCG, scale: uprightImage.scale, orientation: .up)
            }
            return self
        }
    
        guard let croppedCG = cg.cropping(to: cropRect) else { return self }
        return UIImage(cgImage: croppedCG, scale: uprightImage.scale, orientation: .up)
    }
    
    /// 将图片内容归一化为 .up 方向，便于与预览坐标一致地进行裁剪
    /// 使用 CoreGraphics 重绘，避免仅修改 orientation 标志导致的坐标错位
    private func am_fixedOrientationUp() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
