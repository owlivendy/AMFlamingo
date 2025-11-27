//
//  AMImageBase64Encoder.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/7/2.
//  Copyright © 2025 shen xiaofei. All rights reserved.
//

// 图片格式枚举
public enum AMImageFormat {
    case png
    case jpeg
}

public enum AMImageBase64EncoderError: Error {
    case EncodeFailed
}

open class AMImageBase64Encoder {
    
    /// 将 UIImage 编码为 Base64 字符串
    /// - Parameters:
    ///   - image: 要编码的图片
    ///   - format: 图片格式（png/jpeg）
    ///   - compressionQuality: JPEG 压缩质量（0-1，仅对 jpeg 有效）
    /// - Returns: Base64 字符串（转换失败返回 nil）
    open class func encode(
        image: UIImage,
        format: AMImageFormat = .jpeg,
        compressionQuality: CGFloat = 0.6
    ) throws -> String {
        // 1. 将 UIImage 转换为 Data（根据格式处理）
        let imageData: Data?
        switch format {
        case .png:
            imageData = image.pngData()
        case .jpeg:
            imageData = image.jpegData(compressionQuality: compressionQuality)
        }
        
        guard let data = imageData else {
            throw AMImageBase64EncoderError.EncodeFailed
        }
        
        // 2. 将 Data 编码为 Base64 字符串
        return data.base64EncodedString(options: [])
    }
}
