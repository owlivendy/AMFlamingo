//
//  AMLocalJSONStorage.swift
//  ChinaHomelife247
//
//  Created by shen xiaofei on 2025/6/23.
//  Copyright © 2025 fei. All rights reserved.
//
import Foundation

// MARK: - 文件保存选项
struct LocalJSONStorageOptions: OptionSet {
    let rawValue: Int
    static let overwrite = LocalJSONStorageOptions(rawValue: 1 << 0) // 覆盖同名文件
    static let permanent = LocalJSONStorageOptions(rawValue: 1 << 1) // 永久保存，不被自动清理
    static let none: LocalJSONStorageOptions = []
}

// MARK: - 通用本地 JSON 存储工具
@objcMembers
final class AMLocalJSONStorage: NSObject {
    static let shared = AMLocalJSONStorage()
    private override init() {
        super.init()
        loadModTimes()
        currentCacheSize = 0
        modTimesQueue.async { [weak self] in
            guard let self = self else { return }
            self.currentCacheSize = self.calculateCacheSize()
        }
    }

    /// 最大缓存容量，单位字节，默认200MB
    @objc public var maxCacheSize: UInt64 = 200 * 1024 * 1024
    /// 当前缓存容量
    private var currentCacheSize: UInt64 = 0

    // 变动时间字典，key: businessDir/businessId, value: 时间戳
    private var modTimes: [String: TimeInterval] = [:]
    private let modTimesFileName = "dir_mod_times.json"
    private let modTimesQueue = DispatchQueue(label: "com.flamingo.AMLocalJSONStorage.modTimesQueue")

    // Swift Codable 对象存储
    func save<T: Encodable>(_ object: T, fileName: String, businessDir: String, businessId: String, options: LocalJSONStorageOptions = [.overwrite]) {
        modTimesQueue.async { [weak self] in
            guard let self = self else { return }
            let key = "\(businessDir)/\(businessId)"
            
            // 根据是否永久保存选择不同的目录
            let isPermanent = options.contains(.permanent)
            let dir = isPermanent ? self.permanentCacheDirectory(businessDir: businessDir, businessId: businessId) : self.cacheDirectory(businessDir: businessDir, businessId: businessId)
            
            // 只有非永久保存的文件才更新变动时间
            if !isPermanent {
                self.modTimes[key] = Date().timeIntervalSince1970
                self.saveModTimes()
            }
            
            // 计算本次写入文件的大小
            let url = dir.appendingPathComponent(fileName)
            var oldFileSize: UInt64 = 0
            if FileManager.default.fileExists(atPath: url.path) {
                oldFileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { UInt64($0) } ?? 0
                if !options.contains(.overwrite) { return }
            }
            // 编码数据
            guard let data = try? JSONEncoder().encode(object) else { return }
            // 先写入临时文件，避免主文件被破坏
            let tmpURL = url.appendingPathExtension("tmp")
            do {
                try data.write(to: tmpURL)
                // 只有非永久保存的文件才计算缓存大小和清理
                if !isPermanent {
                    let newFileSize = UInt64(data.count)
                    let sizeDelta = Int64(newFileSize) - Int64(oldFileSize)
                    self.currentCacheSize = UInt64(Int64(self.currentCacheSize) + sizeDelta)
                    if self.currentCacheSize > self.maxCacheSize {
                        self.cleanIfNeeded()
                    }
                }
                // 替换正式文件
                try? FileManager.default.removeItem(at: url)
                try FileManager.default.moveItem(at: tmpURL, to: url)
            } catch {
                try? FileManager.default.removeItem(at: tmpURL)
                AMLogDebug("保存缓存失败: \(error)")
            }
        }
    }
    func load<T: Decodable>(_ type: T.Type, fileName: String, businessDir: String, businessId: String) -> T? {
        let dir = cacheDirectory(businessDir: businessDir, businessId: businessId)
        let url = dir.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    // 加载永久保存的数据
    func loadPermanent<T: Decodable>(_ type: T.Type, fileName: String, businessDir: String, businessId: String) -> T? {
        let dir = permanentCacheDirectory(businessDir: businessDir, businessId: businessId)
        let url = dir.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    // OC Model: NSDictionary/NSArray 存储
    @objc public func saveOC(_ object: Any, fileName: String, businessDir: String, businessId: String, overwrite: Bool = true, permanent: Bool = false) {
        modTimesQueue.async { [weak self] in
            guard let self = self else { return }
            let key = "\(businessDir)/\(businessId)"
            
            // 根据是否永久保存选择不同的目录
            let dir = permanent ? self.permanentCacheDirectory(businessDir: businessDir, businessId: businessId) : self.cacheDirectory(businessDir: businessDir, businessId: businessId)
            
            // 只有非永久保存的文件才更新变动时间
            if !permanent {
                self.modTimes[key] = Date().timeIntervalSince1970
                self.saveModTimes()
            }
            
            let url = dir.appendingPathComponent(fileName)
            var oldFileSize: UInt64 = 0
            if FileManager.default.fileExists(atPath: url.path) {
                oldFileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { UInt64($0) } ?? 0
                if !overwrite { return }
            }
            // 写入临时文件
            let tmpURL = url.appendingPathExtension("tmp")
            var newFileSize: UInt64 = 0
            if let dict = object as? NSDictionary {
                dict.write(to: tmpURL, atomically: true)
                newFileSize = (try? tmpURL.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { UInt64($0) } ?? 0
            } else if let array = object as? NSArray {
                array.write(to: tmpURL, atomically: true)
                newFileSize = (try? tmpURL.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { UInt64($0) } ?? 0
            }
            
            // 只有非永久保存的文件才计算缓存大小和清理
            if !permanent {
                let sizeDelta = Int64(newFileSize) - Int64(oldFileSize)
                self.currentCacheSize = UInt64(Int64(self.currentCacheSize) + sizeDelta)
                if self.currentCacheSize > self.maxCacheSize {
                    self.cleanIfNeeded()
                }
            }
            
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.moveItem(at: tmpURL, to: url)
        }
    }
    @objc public func loadOCDictionary(fileName: String, businessDir: String, businessId: String) -> NSDictionary? {
        let dir = cacheDirectory(businessDir: businessDir, businessId: businessId)
        let url = dir.appendingPathComponent(fileName)
        return NSDictionary(contentsOf: url)
    }
    @objc public func loadOCArray(fileName: String, businessDir: String, businessId: String) -> NSArray? {
        let dir = cacheDirectory(businessDir: businessDir, businessId: businessId)
        let url = dir.appendingPathComponent(fileName)
        return NSArray(contentsOf: url)
    }
    @objc public func remove(fileName: String, businessDir: String, businessId: String) {
        modTimesQueue.async { [weak self] in
            guard let self = self else { return }
            let dir = self.cacheDirectory(businessDir: businessDir, businessId: businessId)
            let url = dir.appendingPathComponent(fileName)
            var oldFileSize: UInt64 = 0
            if FileManager.default.fileExists(atPath: url.path) {
                oldFileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { UInt64($0) } ?? 0
            }
            try? FileManager.default.removeItem(at: url)
            self.currentCacheSize = self.currentCacheSize > oldFileSize ? self.currentCacheSize - oldFileSize : 0
            let key = "\(businessDir)/\(businessId)"
            self.modTimes[key] = Date().timeIntervalSince1970
            self.saveModTimes()
        }
    }
    
    // 删除永久保存的文件
    @objc public func removePermanent(fileName: String, businessDir: String, businessId: String) {
        modTimesQueue.async { [weak self] in
            guard let self = self else { return }
            let dir = self.permanentCacheDirectory(businessDir: businessDir, businessId: businessId)
            let url = dir.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    // 整组删除：删除整个业务id目录
    @objc public func removeGroup(businessDir: String, businessId: String) {
        modTimesQueue.async { [weak self] in
            guard let self = self else { return }
            let dir = self.cacheDirectory(businessDir: businessDir, businessId: businessId)
            let size = self.directorySize(at: dir)
            try? FileManager.default.removeItem(at: dir)
            self.currentCacheSize = self.currentCacheSize > size ? self.currentCacheSize - size : 0
            let key = "\(businessDir)/\(businessId)"
            self.modTimes.removeValue(forKey: key)
            self.saveModTimes()
        }
    }
    
    // 删除整个永久保存的业务id目录
    @objc public func removePermanentGroup(businessDir: String, businessId: String) {
        modTimesQueue.async { [weak self] in
            guard let self = self else { return }
            let dir = self.permanentCacheDirectory(businessDir: businessDir, businessId: businessId)
            try? FileManager.default.removeItem(at: dir)
        }
    }
    
    // 加载永久保存的字典数据
    @objc public func loadOCPermanentDictionary(fileName: String, businessDir: String, businessId: String) -> NSDictionary? {
        let dir = permanentCacheDirectory(businessDir: businessDir, businessId: businessId)
        let url = dir.appendingPathComponent(fileName)
        return NSDictionary(contentsOf: url)
    }
    
    // 加载永久保存的数组数据
    @objc public func loadOCPermanentArray(fileName: String, businessDir: String, businessId: String) -> NSArray? {
        let dir = permanentCacheDirectory(businessDir: businessDir, businessId: businessId)
        let url = dir.appendingPathComponent(fileName)
        return NSArray(contentsOf: url)
    }
    
    // MARK: - 文件存在性检查
    
    /// 检查普通缓存文件是否存在
    @objc public func fileExists(fileName: String, businessDir: String, businessId: String) -> Bool {
        let dir = cacheDirectory(businessDir: businessDir, businessId: businessId)
        let url = dir.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    /// 检查永久保存文件是否存在
    @objc public func permanentFileExists(fileName: String, businessDir: String, businessId: String) -> Bool {
        let dir = permanentCacheDirectory(businessDir: businessDir, businessId: businessId)
        let url = dir.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    /// 获取永久保存目录的总大小
    @objc public func getPermanentCacheSize() -> UInt64 {
        let url = permanentCacheRootURL()
        var size: UInt64 = 0
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [], errorHandler: nil) {
            for case let fileURL as URL in enumerator {
                let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                size += UInt64(fileSize)
            }
        }
        return size
    }
    
    /// 删除所有永久保存的文件
    @objc public func removeAllPermanentFiles() {
        modTimesQueue.async { [weak self] in
            guard let self = self else { return }
            let url = self.permanentCacheRootURL()
            try? FileManager.default.removeItem(at: url)
            // 重新创建空目录
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    /// 获取永久保存目录的路径
    @objc public func getPermanentCachePath() -> String {
        return permanentCacheRootURL().path
    }
    
    /// 获取指定永久保存业务目录下的所有文件路径
    @objc public func getAllPermanentFilePaths(businessDir: String) -> [URL] {
        let businessDirURL = permanentCacheDirectory(businessDir: businessDir)
        //遍历dir目录下所有文件
        var fileURLs: [URL] = []
        if let contents = try? FileManager.default.contentsOfDirectory(at: businessDirURL, includingPropertiesForKeys: nil) {
            for dirURL in contents {
                // 遍历dirURL目录下所有文件, 排除文件夹路径, 只保留文件路径
                if let contents = try? FileManager.default.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil) {
                    for fileURL in contents {
                        if !fileURL.hasDirectoryPath {
                            fileURLs.append(fileURL)
                        }
                    }
                }
            }
        }
        return fileURLs
    }
}

private extension AMLocalJSONStorage {
    
    // 获取 JSONCache 根目录
    private func cacheRootURL() -> URL {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let bundleId = Bundle.main.bundleIdentifier ?? "default_bundle"
        return urls[0].appendingPathComponent(bundleId).appendingPathComponent("JSONCache")
    }
    
    // 获取永久保存目录
    private func permanentCacheRootURL() -> URL {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let bundleId = Bundle.main.bundleIdentifier ?? "default_bundle"
        return urls[0].appendingPathComponent(bundleId).appendingPathComponent("JSONCache_Permanent")
    }

    // 获取缓存目录 caches/{bundle id}/JSONCache/{业务目录}/{业务id}
    private func cacheDirectory(businessDir: String, businessId: String) -> URL {
        let dir = cacheRootURL().appendingPathComponent(businessDir).appendingPathComponent(businessId)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    // 获取永久保存目录 caches/{bundle id}/JSONCache_Permanent/{业务目录}/{业务id}
    private func permanentCacheDirectory(businessDir: String, businessId: String? = nil) -> URL {
        var dir = permanentCacheRootURL().appendingPathComponent(businessDir)
        if let businessId = businessId {
            dir = dir.appendingPathComponent(businessId)
        }
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    // 变动时间字典文件
    private func modTimesFileURL() -> URL {
        return cacheRootURL().appendingPathComponent(modTimesFileName)
    }
    // 加载变动时间字典
    private func loadModTimes() {
        let url = modTimesFileURL()
        if let data = try? Data(contentsOf: url),
           let dict = try? JSONDecoder().decode([String: TimeInterval].self, from: data) {
            modTimes = dict
        }
    }
    // 保存变动时间字典
    private func saveModTimes() {
        let url = modTimesFileURL()
        if let data = try? JSONEncoder().encode(modTimes) {
            try? data.write(to: url)
        }
    }
    // 计算目录大小（全量遍历）
    private func calculateCacheSize() -> UInt64 {
        let url = cacheRootURL()
        var size: UInt64 = 0
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [], errorHandler: nil) {
            for case let fileURL as URL in enumerator {
                let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                size += UInt64(fileSize)
            }
        }
        return size
    }
    // 获取单个 businessId 目录大小
    private func directorySize(at url: URL) -> UInt64 {
        var size: UInt64 = 0
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [], errorHandler: nil) {
            for case let fileURL as URL in enumerator {
                let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                size += UInt64(fileSize)
            }
        }
        return size
    }
    // 清理超出容量的 businessId 文件夹（FIFO），异步执行
    private func cleanIfNeededAsync() {
        modTimesQueue.async { [weak self] in
            self?.cleanIfNeeded()
        }
    }
    // 串行队列内执行的清理逻辑
    private func cleanIfNeeded() {
        guard currentCacheSize > maxCacheSize else { return }
        let root = cacheRootURL()
        let sorted: [(String, TimeInterval)] = modTimes.sorted { $0.value < $1.value }
        var currentSize = currentCacheSize
        for (key, _) in sorted {
            let path = root.appendingPathComponent(key)
            if FileManager.default.fileExists(atPath: path.path) {
                let size = directorySize(at: path)
                try? FileManager.default.removeItem(at: path)
                modTimes.removeValue(forKey: key)
                saveModTimes()
                currentSize -= size
                currentCacheSize = currentSize
                if currentSize <= maxCacheSize { break }
            }
        }
    }
}
