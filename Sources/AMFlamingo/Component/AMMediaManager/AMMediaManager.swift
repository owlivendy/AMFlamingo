//
//  AMMediaManager.swift
//  ChinaHomelife247
//
//  Created by meotech on 2025/9/8.
//  Copyright © 2025 吕欢. All rights reserved.
//

import UIKit
import Darwin
import ImageIO
import MobileCoreServices
import Photos

// MARK: 2. 错误枚举（沿用原有，新增时区相关错误）
@objc enum CHDataError: Int, Error {
    case invalidImageData         // 无效图片数据
    case invalidFilePath
    case invalidFileData
}

// MARK: 3. 核心管理类（修改保存/获取逻辑，支持时区适配）
@objcMembers
class AMMediaManager: NSObject {
    private let thumbnailDir = "thumbnail"
    private let thumbnailFileExt = "thumbnail"
    // 依赖的用户目录管理器
    private let directoryManager = AMUserDirectoryManager.shared
    // 眼镜设备标识
    let glassesIdentifier: String
    
    // --- 日期格式化器调整：区分“拍摄时区”和“当前时区” ---
    /// 通用日期格式化器（用于解析/生成 yyyy-MM-dd 格式，需动态设置时区）
    private func dateFormatter(for timezoneId: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale(identifier: "zh_CN")
        // 优先用指定时区，否则用设备当前时区（兜底）
        formatter.timeZone = TimeZone(identifier: timezoneId) ?? TimeZone.current
        return formatter
    }
    
    /// 图片名称中的时间格式化器（UTC时间戳，避免时区影响唯一性）
    private let mediaTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmssSSS" // 精确到毫秒（避免同一秒多次保存重名）
        formatter.timeZone = TimeZone(identifier: "UTC") // 用UTC时间，确保全球唯一
        formatter.locale = Locale(identifier: "en_US_POSIX") // 避免区域设置影响格式
        return formatter
    }()
    
    // 初始化（沿用原有逻辑）
    init(glassesIdentifier: String) {
        self.glassesIdentifier = glassesIdentifier
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "_")
        super.init()
    }
    
    // 沿用原有辅助方法（getGlassesBaseDirectory、getImageFormatAndExtension）
    func getGlassesBaseDirectory() -> URL? {
        let docDir = directoryManager.userDocumentDirectory() 
        let glassesDir = docDir.appendingPathComponent(glassesIdentifier)
        try? FileManager.default.createDirectory(at: glassesDir, withIntermediateDirectories: true)
        return glassesDir
    }
    
    /// 将指定路径的文件移动到新路径（与图片相同的存储结构）
    /// - Parameter path: 源文件路径
    /// - Throws: 可能抛出的错误（路径无效、移动失败等）
    func saveMedia(from path: String) throws -> AMMediaModel {
        // 1. 校验源文件路径有效性
        let sourceUrl = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else {
            throw CHDataError.invalidFilePath
        }
        
        // 2. 获取文件类型和扩展名
        let fileExtension = sourceUrl.pathExtension.lowercased()
        guard !fileExtension.isEmpty else {
            throw CHDataError.invalidFileData
        }
        
        // 3. 准备时间相关信息
        let captureTimezoneId = TimeZone.current.identifier
//        let captureTimestamp = Date().timeIntervalSince1970 * 1000
        
        // 4. 获取基础目录（与图片共用同一基础目录）
        guard let baseDir = getGlassesBaseDirectory() else {
            throw NSError(domain: "CHMediaManager", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "无法获取基础目录"])
        }
        
        // 5. 按 bucket 分文件夹（与图片保持相同的分桶逻辑）
        let bucketSize = 1000
        let existingBuckets = (try? FileManager.default.contentsOfDirectory(at: baseDir,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles).filter { url in
                var isDir: ObjCBool = false
                return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
            }) ?? []
        
        // 确定目标 bucket
        let lastBucket = existingBuckets.sorted { $0.lastPathComponent < $1.lastPathComponent }.last
        var targetBucket: URL
        if let last = lastBucket,
           let files = try? FileManager.default.contentsOfDirectory(at: last, includingPropertiesForKeys: nil),
           files.count < bucketSize {
            targetBucket = last
        } else {
            // 新建 bucket（序号与图片 bucket 连续）
            let newIndex = (existingBuckets.count + 1)
            targetBucket = baseDir.appendingPathComponent(String(format: "bucket_%04d", newIndex))
            try FileManager.default.createDirectory(at: targetBucket, withIntermediateDirectories: true)
        }
        
        // 6. 生成目标文件名（与图片命名规则一致）
        let utcTimeStr = mediaTimestampFormatter.string(from: Date())
        let mediaName = "MED_\(utcTimeStr).\(fileExtension)" // 使用MED前缀区分媒体文件
        let targetUrl = targetBucket.appendingPathComponent(mediaName)
        
        // 7. 移动文件到目标路径（如果目标已存在则覆盖）
        if FileManager.default.fileExists(atPath: targetUrl.path) {
            try FileManager.default.removeItem(at: targetUrl)
        }
        try FileManager.default.moveItem(at: sourceUrl, to: targetUrl)
        
        // 8. 写入扩展属性（与图片保持一致的元数据）
        try setTimezoneToFileMetadata(targetUrl, timezoneId: captureTimezoneId)
        let thumbnailPath = try generateAndSaveThumbnail(for: targetUrl)
        
        AMLogDebug("成功移动媒体文件：\(targetUrl.path)")
        
        
        let mediaType: AMMediaType = fileExtension == "mp4" ? .video : .image
        let timestamp = Date().timeIntervalSince1970 * 1000
        return AMMediaModel(url: targetUrl,
                            thumbnail: thumbnailPath,
                            mediaType: mediaType,
                                 name: mediaName,
                    captureTimezoneId: TimeZone.current.identifier,
                     captureTimestamp: timestamp)
    }
    
    /// 生成图片/视频缩略图并保存到指定路径
    /// - Parameter filePath: 源文件URL（支持JPG/PNG/MP4）
    /// - Throws: 可能抛出的错误（文件不存在、格式不支持、生成失败等）
    func generateAndSaveThumbnail(for filePath: URL) throws -> URL {
        // 1. 基础校验：文件是否存在
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            throw NSError(domain: "ThumbnailGenerator", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "源文件不存在：\(filePath.path)"])
        }
        
        // 2. 解析文件信息：扩展名、文件名、目标路径
        let fileExt = filePath.pathExtension.lowercased() // 小写化扩展名（兼容大小写）
        let fileName = filePath.deletingPathExtension().lastPathComponent // 原始文件名（不含扩展名）
        let sourceDir = filePath.deletingLastPathComponent() // 源文件所在目录
        
        // 2.1 创建目标目录：源目录下的 "thumbnail" 文件夹
        let targetDir = sourceDir.appendingPathComponent(thumbnailDir)
        if !FileManager.default.fileExists(atPath: targetDir.path) {
            try FileManager.default.createDirectory(at: targetDir,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        }
        
        // 3. 根据文件类型生成缩略图
        let thumbnailImage: UIImage
        
        switch fileExt {
        case "jpg", "jpeg", "png":
            // 3.1 图片文件：直接生成缩略图
            guard let sourceImage = UIImage(contentsOfFile: filePath.path) else {
                throw NSError(domain: "ThumbnailGenerator", code: -2,
                              userInfo: [NSLocalizedDescriptionKey: "图片文件解析失败：\(filePath.path)"])
            }
            // 生成缩略图（建议尺寸：200x200，可根据需求调整）
            thumbnailImage = sourceImage.scaledToThumbnailSize(maxSize: CGSize(width: 200, height: 200))
        
        case "mp4":
            // 3.2 视频文件：提取首帧作为缩略图
            thumbnailImage = try extractVideoFirstFrame(videoURL: filePath)
        
        default:
            // 3.3 不支持的文件类型
            throw NSError(domain: "ThumbnailGenerator", code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "不支持的文件格式：\(fileExt)"])
        }
        
        // 4. 生成目标文件URL（命名规则：{原文件名}.thumbnail.{扩展名}）
        let targetFileName = "\(fileName).\(thumbnailFileExt)"
        let targetURL = targetDir.appendingPathComponent(targetFileName)
        
        // 5. 保存缩略图到目标路径（覆盖已存在文件）
        if FileManager.default.fileExists(atPath: targetURL.path) {
            try FileManager.default.removeItem(at: targetURL) // 先删除旧文件
        }
        
        // 保存缩略图
        // JPG格式（含视频缩略图）：压缩质量0.8（平衡质量与体积）
        guard let jpgData = thumbnailImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ThumbnailGenerator", code: -5,
                          userInfo: [NSLocalizedDescriptionKey: "JPG缩略图编码失败"])
        }
        try jpgData.write(to: targetURL)
        
        AMLogDebug("缩略图生成成功：\n源文件：\(filePath.path)\n目标路径：\(targetURL.path)")
        
        return targetURL
    }
    
    // MARK: 5. 获取图片：按“拍摄时区的本地日期”分组（核心适配）
    func getAllPhotosGroupedByDate() -> [AMMediaGroupModel]? {
        guard let baseDir = getGlassesBaseDirectory() else {
            print("❌ 无法获取基础目录")
            return nil
        }

        // 1. 获取所有图片（递归所有 bucket）
        guard let enumerator = FileManager.default.enumerator(
            at: baseDir,
            includingPropertiesForKeys: [.isRegularFileKey, .creationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        var photoModels: [AMMediaModel] = []
        let validExtensions = ["jpg", "jpeg", "png", "heic", "gif", "tiff", "mp4"]

        for case let file as URL in enumerator {
            if !validExtensions.contains(file.pathExtension.lowercased()) { continue }

            let fileName = file.lastPathComponent
            let fileExtension = file.pathExtension

            // 🔑 获取文件的创建时间
            let resourceValues = try? file.resourceValues(forKeys: [.creationDateKey])
            guard let creationDate = resourceValues?.creationDate else {
                continue
            }

            let captureTimestamp = creationDate.timeIntervalSince1970 * 1000 // 毫秒

            let captureTimezoneId: String
            if let tz = try? getTimezoneFromFileMetadata(file), !tz.isEmpty {
                captureTimezoneId = tz
            } else {
                captureTimezoneId = TimeZone.current.identifier
            }
            let fileNameWithoutExt = file.deletingPathExtension().lastPathComponent
            let thumbnailp = file.deletingLastPathComponent().appendingPathComponent(thumbnailDir).appendingPathComponent("\(fileNameWithoutExt).\(thumbnailFileExt)")
            
            AMLogDebug("thumbnail path: \(thumbnailp)")
            let mediaType: AMMediaType  = fileExtension == "mp4" ? .video : .image
            photoModels.append(AMMediaModel(
                url: file,
                thumbnail: thumbnailp,
                mediaType: mediaType,
                name: fileName,
                captureTimezoneId: captureTimezoneId,
                captureTimestamp: captureTimestamp
            ))
        }

        // 2. 分组（按设备当前时区）
        let currentTzId = TimeZone.current.identifier
        let formatter = self.dateFormatter(for: currentTzId)

        let dateGroups = Dictionary(grouping: photoModels) { model in
            let captureDate = Date(timeIntervalSince1970: model.captureTimestamp / 1000)
            return formatter.string(from: captureDate)
        }

        // 3. 排序：先按日期降序，每组内的媒体按 captureTimestamp 降序（最新的在前）
        return dateGroups.map { (date, medias) in
            // 对当前组内的媒体按 captureTimestamp 降序排序
            let sortedMedias = medias.sorted { $0.captureTimestamp > $1.captureTimestamp }
            return AMMediaGroupModel(date: date, medias: sortedMedias)
        }.sorted { $0.date > $1.date } // 日期分组整体按日期降序
    }

}

// MARK: 6. 辅助方法：读取文件元数据中的时区（保存时需写入）
private extension AMMediaManager {
    /// 从文件元数据读取拍摄时区（优先扩展属性，兜底 EXIF → 设备时区）
    func getTimezoneFromFileMetadata(_ fileUrl: URL) throws -> String? {
        // 1. 优先读扩展属性
        if let data = try readExtendedAttribute(named: "captureTimezone", from: fileUrl),
           let tzId = String(data: data, encoding: .utf8),
           !tzId.isEmpty {
            return tzId
        }

        // 2. 兜底：从 EXIF 解析 OffsetTimeOriginal
        guard let src = CGImageSourceCreateWithURL(fileUrl as CFURL, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [String: Any],
              let exif = props[kCGImagePropertyExifDictionary as String] as? [String: Any],
              let offsetStr = exif[kCGImagePropertyExifOffsetTimeOriginal as String] as? String else {
            return nil
        }

        // offsetStr 格式一般是 "+08:00" 或 "-04:00"
        if let tz = Self.timeZoneFromOffset(offsetStr) {
            return tz.identifier
        }

        return nil
    }

    /// 将 "+08:00" / "-04:00" 等字符串解析为 TimeZone
    static func timeZoneFromOffset(_ offset: String) -> TimeZone? {
        // 解析 "+HH:mm" / "-HH:mm"
        let pattern = #"^([+-])(\d{2}):(\d{2})$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: offset, range: NSRange(offset.startIndex..., in: offset)),
              match.numberOfRanges == 4 else {
            return nil
        }

        func substring(_ rangeIdx: Int) -> String {
            let range = Range(match.range(at: rangeIdx), in: offset)!
            return String(offset[range])
        }

        let sign = substring(1) == "-" ? -1 : 1
        let hours = Int(substring(2)) ?? 0
        let minutes = Int(substring(3)) ?? 0
        let totalSeconds = sign * (hours * 3600 + minutes * 60)

        return TimeZone(secondsFromGMT: totalSeconds)
    }

    private func readExtendedAttribute(named name: String, from url: URL) throws -> Data? {
        return try url.withUnsafeFileSystemRepresentation { path -> Data? in
            guard let path = path else {
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(EINVAL))
            }
            // 第一次调用获取所需缓冲区大小
            let size = getxattr(path, name, nil, 0, 0, 0)
            if size == -1 {
                // 属性不存在：返回 nil（不当成错误）
                if errno == ENOATTR /* macOS/iOS */ || errno == ENODATA /* 其他平台 */ {
                    return nil
                }
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
            }

            var data = Data(count: Int(size))
            let readSize = data.withUnsafeMutableBytes { buf -> ssize_t in
                guard let base = buf.baseAddress else { return -1 }
                return getxattr(path, name, base, Int(size), 0, 0)
            }
            if readSize == -1 {
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
            }
            data.count = Int(readSize)
            return data
        }
    }
    
    /// 保存时将时区写入文件元数据（扩展savePhoto方法）
    func setTimezoneToFileMetadata(_ fileUrl: URL, timezoneId: String) throws {
        let attrName = "captureTimezone"
        let value = Data(timezoneId.utf8)
        try writeExtendedAttribute(named: attrName, value: value, to: fileUrl)
    }

    private func writeExtendedAttribute(named name: String, value: Data, to url: URL) throws {
        try url.withUnsafeFileSystemRepresentation { path in
            guard let path = path else {
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(EINVAL))
            }
            let result = value.withUnsafeBytes { buf -> Int32 in
                let base = buf.baseAddress
                return setxattr(path, name, base, value.count, 0, 0) // 可换 XATTR_CREATE / XATTR_REPLACE
            }
            if result == -1 {
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
            }
        }
    }
    
    func getImageFormatAndExtension(from data: Data) -> (format: String, extension: String)? {
        guard data.count >= 8 else { return nil }
        let headerBytes = [UInt8](data.subdata(in: 0..<8))
        
        if headerBytes[0] == 0xFF && headerBytes[1] == 0xD8 && headerBytes[2] == 0xFF {
            return ("JPEG", "jpg")
        } else if headerBytes[0] == 0x89 && headerBytes[1] == 0x50 && headerBytes[2] == 0x4E && headerBytes[3] == 0x47 &&
                  headerBytes[4] == 0x0D && headerBytes[5] == 0x0A && headerBytes[6] == 0x1A && headerBytes[7] == 0x0A {
            return ("PNG", "png")
        } else if data.count >= 12, let ftypHeader = String(data: data.subdata(in: 4..<12), encoding: .utf8),
                  ftypHeader.hasPrefix("ftypheic") || ftypHeader.hasPrefix("ftypheix") {
            return ("HEIC", "heic")
        } else {
            return nil
        }
    }
    
    /// 提取视频首帧作为图片
    /// - Parameter videoURL: 视频文件URL
    /// - Returns: 视频首帧图片
    /// - Throws: 视频解析失败时抛出错误
    private func extractVideoFirstFrame(videoURL: URL) throws -> UIImage {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true // 保持视频方向（避免旋转问题）
        imageGenerator.maximumSize = CGSize(width: 200, height: 200) // 限制缩略图最大尺寸
        
        // 取视频起始位置（0秒处）的帧
        let time = CMTime(seconds: 0, preferredTimescale: 600)
        var actualTime = CMTime.zero
        
        guard let cgImage = try? imageGenerator.copyCGImage(at: time, actualTime: &actualTime) else {
            throw NSError(domain: "ThumbnailGenerator", code: -6,
                          userInfo: [NSLocalizedDescriptionKey: "视频首帧提取失败：\(videoURL.path)"])
        }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - 辅助方法
extension UIImage {
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
