//
//  CHGlassesPhotoModel.swift
//  ChinaHomelife247
//
//  Created by meotech on 2025/9/8.
//  Copyright © 2025 吕欢. All rights reserved.
//

import Foundation

@objc enum AMMediaType: Int {
    case video
    case image
}
// MARK: 1. 扩展模型：新增时区相关属性（记录拍摄时区）
/// 单张眼镜照片模型（新增拍摄时区字段）
@objcMembers
class AMMediaModel: NSObject {
    
    let mediaType: AMMediaType
    let url: URL                  // 图片路径
    let thumbnailUrl: URL?
    let name: String              // 图片名称（含扩展名）
    let captureTimezoneId: String // 拍摄时的时区标识（如 Asia/Shanghai）
    let captureTimestamp: Double // 拍摄时的UTC时间戳（毫秒级，确保唯一性）
    
    init(url: URL, thumbnail: URL?, mediaType: AMMediaType, name: String, captureTimezoneId: String, captureTimestamp: Double) {
        self.url = url
        self.thumbnailUrl = thumbnail
        self.mediaType = mediaType
        self.name = name
        self.captureTimezoneId = captureTimezoneId
        self.captureTimestamp = captureTimestamp
    }
}

/// 按日期分组的眼镜照片模型（保持原有结构，日期基于拍摄时区解析）
@objcMembers
class AMMediaGroupModel: NSObject {
    let date: String              // 拍摄时的本地日期（yyyy-MM-dd，如北京时区的2025-09-01）
    var medias: [AMMediaModel]
    
    init(date: String, medias: [AMMediaModel]) {
        self.date = date
        self.medias = medias
    }
}
