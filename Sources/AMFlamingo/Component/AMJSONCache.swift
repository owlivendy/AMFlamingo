//
//  AMJSONCache.swift
//  ChinaHomelife247
//
//  Created by shen xiaofei on 2025/10/28.
//  Copyright © 2025 shen xiaofei. All rights reserved.
//

import Foundation
import CommonCrypto

public final class AMJSONCache {

    static let shared = AMJSONCache()
    private init() { setup() }

    private var cacheDir: URL!
    private var metadataURL: URL!
    private var metadata: NSMutableDictionary = NSMutableDictionary()
    private var maxCount: UInt = 1000
    private var maxSizeBytes: UInt = 100 * 1024 * 1024

    // MARK: - 初始化
    private func setup() {
        // 缓存目录
        if let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            cacheDir = cachesURL.appendingPathComponent("com.jsoncache.am")
            try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }

        // metadata 路径
        metadataURL = cacheDir.appendingPathComponent("metadata.plist")

        // 加载 metadata
        if let data = try? Data(contentsOf: metadataURL),
           let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? NSDictionary {

            if let items = dict["items"] as? NSDictionary,
               let totalCount = dict["totalCount"] as? UInt,
               let totalSize = dict["totalSize"] as? UInt {

                metadata = NSMutableDictionary(dictionary: [
                    "totalCount": totalCount,
                    "totalSize": totalSize,
                    "items": NSMutableDictionary(dictionary: items)
                ])

                return
            }
        }

        // 初始化默认结构
        metadata = [
            "totalCount": 0,
            "totalSize": 0,
            "items": NSMutableDictionary()
        ]
        saveMetadata()
    }

    // MARK: - 配置
    public func setCacheLimit(maxCount: UInt, maxSizeMB: UInt) {
        self.maxCount = maxCount
        self.maxSizeBytes = maxSizeMB * 1024 * 1024
    }

    // MARK: - 保存 JSON
    public func saveJSON(_ json: Any, forKey key: String) {
        guard JSONSerialization.isValidJSONObject(json), !key.isEmpty else { return }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: json) else { return }

        let fileName = key.md5()
        let fileURL = cacheDir.appendingPathComponent(fileName)

        do {
            try jsonData.write(to: fileURL)
        } catch {
            print("写入 JSON 失败: \(error)")
            return
        }

        let items = (metadata["items"] as? NSMutableDictionary) ?? NSMutableDictionary()
        metadata["items"] = items

        let oldSize = (items[key] as? [String: Any])?["size"] as? UInt ?? 0

        if items[key] == nil {
            metadata["totalCount"] = (metadata["totalCount"] as? UInt ?? 0) + 1
        }

        items[key] = [
            "accessTime": Date.timeIntervalSinceReferenceDate,
            "size": UInt(jsonData.count)
        ]

        let totalSize = (metadata["totalSize"] as? UInt ?? 0)
        metadata["totalSize"] = totalSize - oldSize + UInt(jsonData.count)

        saveMetadata()
        trimCacheIfNeeded()
    }

    // MARK: - 获取 JSON
    public func getJSON(forKey key: String) -> Any? {
        guard !key.isEmpty else { return nil }

        let fileName = key.md5()
        let fileURL = cacheDir.appendingPathComponent(fileName)

        guard let jsonData = try? Data(contentsOf: fileURL),
              let json = try? JSONSerialization.jsonObject(with: jsonData) else {
            removeJSON(forKey: key)
            return nil
        }

        if let items = metadata["items"] as? NSMutableDictionary,
           var item = items[key] as? [String: Any] {
            item["accessTime"] = Date.timeIntervalSinceReferenceDate
            items[key] = item
            saveMetadata()
        }

        return json
    }

    // MARK: - 删除 JSON
    public func removeJSON(forKey key: String) {
        guard !key.isEmpty else { return }

        let fileName = key.md5()
        let fileURL = cacheDir.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)

        guard let items = metadata["items"] as? NSMutableDictionary,
              let item = items[key] as? [String: Any],
              let size = item["size"] as? UInt
        else { return }

        let count = metadata["totalCount"] as? UInt ?? 1
        metadata["totalCount"] = max(count - 1, 0)

        let totalSize = metadata["totalSize"] as? UInt ?? size
        metadata["totalSize"] = max(totalSize - size, 0)

        items.removeObject(forKey: key)
        saveMetadata()
    }

    // MARK: - 清空
    public func clearAllCache() {
        if let files = try? FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil) {
            for fileURL in files where fileURL.lastPathComponent != "metadata.plist" {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }

        metadata["totalCount"] = 0
        metadata["totalSize"] = 0
        (metadata["items"] as? NSMutableDictionary)?.removeAllObjects()
        saveMetadata()
    }

    // MARK: - LRU
    private func trimCacheIfNeeded() {
        let count = metadata["totalCount"] as? UInt ?? 0
        let size = metadata["totalSize"] as? UInt ?? 0

        guard count > maxCount || size > maxSizeBytes else { return }

        guard let items = metadata["items"] as? NSMutableDictionary else { return }

        let dict = items as? [String: [String: Any]] ?? [:]

        let sortedKeys = dict.keys.sorted {
            let t1 = dict[$0]?["accessTime"] as? TimeInterval ?? 0
            let t2 = dict[$1]?["accessTime"] as? TimeInterval ?? 0
            return t1 < t2
        }

        for key in sortedKeys {
            removeJSON(forKey: key)

            let c = metadata["totalCount"] as? UInt ?? 0
            let s = metadata["totalSize"] as? UInt ?? 0
            if c <= maxCount && s <= maxSizeBytes {
                break
            }
        }
    }

    // MARK: - 保存 metadata
    private func saveMetadata() {
        if let data = try? PropertyListSerialization.data(fromPropertyList: metadata, format: .binary, options: 0) {
            try? data.write(to: metadataURL)
        }
    }
}

extension String {
    func md5() -> String {
        let cStr = self.cString(using: .utf8) ?? []
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5(cStr, CC_LONG(strlen(cStr)), result)
        let str = (0..<Int(CC_MD5_DIGEST_LENGTH)).map { String(format: "%02x", result[$0]) }.joined()
        result.deallocate()
        return str
    }
}
