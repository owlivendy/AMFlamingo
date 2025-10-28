//
//  AMJSONCache.swift
//  ChinaHomelife247
//
//  Created by shen xiaofei on 2025/10/28.
//  Copyright © 2025 shen xiaofei. All rights reserved.
//

import Foundation
import CommonCrypto

class AMJSONCache {
    // 单例
    static let shared = AMJSONCache()
    private init() { setup() }
    
    // 缓存目录路径
    private var cacheDir: URL!
    // 元数据文件路径
    private var metadataURL: URL!
    // 元数据内存缓存（结构：[String: [String: Any]] 包含 totalCount, totalSize, items）
    private var metadata: NSMutableDictionary!
    // 最大缓存个数（默认1000）
    private var maxCount: UInt = 1000
    // 最大缓存大小（字节，默认100MB）
    private var maxSizeBytes: UInt = 100 * 1024 * 1024
    
    // MARK: - 初始化
    
    private func setup() {
        // 1. 创建缓存目录（Caches/AMJSONCache）
        if let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            cacheDir = cachesURL.appendingPathComponent("com.jsoncache.am")
            try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }
        
        // 2. 初始化元数据
        metadataURL = cacheDir.appendingPathComponent("metadata.plist")
        if FileManager.default.fileExists(atPath: metadataURL.path) {
            if let data = try? Data(contentsOf: metadataURL),
               let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? NSMutableDictionary {
                metadata = dict
            }
        }
        // 元数据结构初始化（若文件不存在或解析失败）
        if metadata == nil {
            metadata = NSMutableDictionary()
            metadata["totalCount"] = 0
            metadata["totalSize"] = 0
            metadata["items"] = NSMutableDictionary() // 存储 key: [accessTime: TimeInterval, size: UInt]
        }
    }
    
    // MARK: - 公开方法
    
    /// 配置缓存限制
    /// - Parameters:
    ///   - maxCount: 最大缓存个数
    ///   - maxSizeMB: 最大缓存大小（MB）
    func setCacheLimit(maxCount: UInt, maxSizeMB: UInt) {
        self.maxCount = maxCount
        self.maxSizeBytes = maxSizeMB * 1024 * 1024
    }
    
    /// 保存JSON数据
    /// - Parameters:
    ///   - json: 要缓存的JSON（支持Dictionary/Array）
    ///   - key: 缓存key
    func saveJSON(_ json: Any, forKey key: String) {
        guard JSONSerialization.isValidJSONObject(json), !key.isEmpty else { return }
        
        // 1. 序列化JSON为Data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json) else { return }
        
        // 2. 计算文件名（key的MD5）
        let fileName = key.md5()
        let fileURL = cacheDir.appendingPathComponent(fileName)
        
        // 3. 写入文件
        do {
            try jsonData.write(to: fileURL)
        } catch {
            print("JSON缓存写入失败：\(error)")
            return
        }
        
        // 4. 更新元数据
        let items = metadata["items"] as! NSMutableDictionary
        var oldSize: UInt = 0
        
        // 若已存在该key，更新大小
        if let item = items[key] as? [String: Any] {
            oldSize = item["size"] as! UInt
        } else {
            // 新缓存，增加计数
            metadata["totalCount"] = (metadata["totalCount"] as! UInt) + 1
        }
        
        // 更新当前key的元数据（访问时间为当前时间）
        items[key] = [
            "accessTime": Date.timeIntervalSinceReferenceDate,
            "size": jsonData.count
        ]
        
        // 更新总大小
        let currentTotalSize = metadata["totalSize"] as! UInt
        metadata["totalSize"] = currentTotalSize - oldSize + UInt(jsonData.count)
        
        // 保存元数据到文件
        saveMetadata()
        
        // 5. 检查并修剪缓存
        trimCacheIfNeeded()
    }
    
    /// 获取缓存的JSON数据
    /// - Parameter key: 缓存key
    /// - Returns: 解析后的JSON（Dictionary/Array，nil表示无缓存或解析失败）
    func getJSON(forKey key: String) -> Any? {
        guard !key.isEmpty else { return nil }
        
        // 1. 检查文件是否存在
        let fileName = key.md5()
        let fileURL = cacheDir.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        
        // 2. 读取并解析JSON
        guard let jsonData = try? Data(contentsOf: fileURL),
              let json = try? JSONSerialization.jsonObject(with: jsonData) else {
            // 解析失败，删除无效文件
            removeJSON(forKey: key)
            return nil
        }
        
        // 3. 更新访问时间（标记为最近使用）
        let items = metadata["items"] as! NSMutableDictionary
        if var item = items[key] as? [String: Any] {
            item["accessTime"] = Date.timeIntervalSinceReferenceDate
            items[key] = item
            saveMetadata()
        }
        
        return json
    }
    
    /// 删除指定key的缓存
    /// - Parameter key: 缓存key
    func removeJSON(forKey key: String) {
        guard !key.isEmpty else { return }
        
        // 1. 删除文件
        let fileName = key.md5()
        let fileURL = cacheDir.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
        
        // 2. 更新元数据
        let items = metadata["items"] as! NSMutableDictionary
        if let item = items[key] as? [String: Any] {
            let size = item["size"] as! UInt
            // 更新总计数和总大小
            metadata["totalCount"] = (metadata["totalCount"] as! UInt) - 1
            metadata["totalSize"] = (metadata["totalSize"] as! UInt) - size
            items.removeObject(forKey: key)
            saveMetadata()
        }
    }
    
    /// 清空所有缓存
    func clearAllCache() {
        // 1. 删除所有缓存文件（保留metadata.plist）
        if let files = try? FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil) {
            for fileURL in files where fileURL.lastPathComponent != "metadata.plist" {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
        
        // 2. 重置元数据
        metadata["totalCount"] = 0
        metadata["totalSize"] = 0
        (metadata["items"] as! NSMutableDictionary).removeAllObjects()
        saveMetadata()
    }
    
    // MARK: - 私有方法：缓存淘汰
    
    /// 检查并修剪缓存（若超限则按LRU淘汰）
    private func trimCacheIfNeeded() {
        let currentCount = metadata["totalCount"] as! UInt
        let currentSize = metadata["totalSize"] as! UInt
        
        // 未超限则返回
        guard currentCount > maxCount || currentSize > maxSizeBytes else { return }
        
        // 1. 获取所有key并按访问时间排序（最久未使用的在前）
        let items = metadata["items"] as! [String: [String: Any]]
        let sortedKeys = items.keys.sorted { key1, key2 in
            let time1 = items[key1]!["accessTime"] as! TimeInterval
            let time2 = items[key2]!["accessTime"] as! TimeInterval
            return time1 < time2 // 升序：旧→新
        }
        
        // 2. 依次删除最久未使用的缓存，直到符合限制
        for key in sortedKeys {
            removeJSON(forKey: key)
            
            // 检查是否已符合限制
            let updatedCount = metadata["totalCount"] as! UInt
            let updatedSize = metadata["totalSize"] as! UInt
            if updatedCount <= maxCount && updatedSize <= maxSizeBytes {
                break
            }
        }
    }
    
    /// 保存元数据到文件
    private func saveMetadata() {
        guard let metadata = metadata else {
            return
        }
        let data = try! PropertyListSerialization.data(fromPropertyList: metadata, format: .binary, options: 0)
        try? data.write(to: metadataURL)
    }
}

// MARK: - 扩展：计算MD5
extension String {
    func md5() -> String {
        let cStr = self.cString(using: .utf8)!
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        
        CC_MD5(cStr, CC_LONG(strlen(cStr)), result)
        
        let md5String = (0..<digestLen).reduce("") { $0 + String(format: "%02x", result[$1]) }
        result.deallocate()
        return md5String
    }
}
