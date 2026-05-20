//
//  AMJSONStorage.swift
//  AMFlamingo
//
//  Local JSON persistence keyed by string path segments (use `/` for subfolders).
//

import Foundation

/// 基于 `Caches/{bundleId}/JSONStorage` 的持久化 JSON 存储（Swift `Codable`）。
public final class AMJSONStorage {
    public static let shared = AMJSONStorage()

    private let ioQueue = DispatchQueue(label: "com.flamingo.AMJSONStorage")

    private init() {}

    // MARK: - Public

    /// 持久化对象。`key` 使用 `/` 分段，最后一段为文件名主体（自动加 `.json`）。
    public func save<T: Encodable>(_ object: T, key: String) {
        ioQueue.async { [weak self] in
            guard let self, let url = self.fileURL(forKey: key) else { return }
            let parent = url.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
            guard let data = try? JSONEncoder().encode(object) else { return }
            let tmpURL = url.appendingPathExtension("tmp")
            do {
                try data.write(to: tmpURL)
                try? FileManager.default.removeItem(at: url)
                try FileManager.default.moveItem(at: tmpURL, to: url)
            } catch {
                try? FileManager.default.removeItem(at: tmpURL)
                AMLogDebug("AMJSONStorage 保存失败: \(error)")
            }
        }
    }

    public func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let url = fileURL(forKey: key) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    public func remove(key: String) {
        ioQueue.async { [weak self] in
            guard let self, let url = self.fileURL(forKey: key) else { return }
            try? FileManager.default.removeItem(at: url)
        }
    }

    public func contains(key: String) -> Bool {
        guard let url = fileURL(forKey: key) else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// 递归列出 `keyPrefix` 目录下所有 `.json` 文件的 URL。
    public func storedFileURLs(keyPrefix: String) -> [URL] {
        let base = directoryURL(forKeyPrefix: keyPrefix)
        guard FileManager.default.fileExists(atPath: base.path) else { return [] }
        var results: [URL] = []
        if let enumerator = FileManager.default.enumerator(
            at: base,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                guard fileURL.pathExtension == "json" else { continue }
                let isFile = (try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) ?? false
                guard isFile else { continue }
                results.append(fileURL)
            }
        }
        return results
    }

    public var storageDirectoryPath: String {
        storageRootURL().path
    }

    // MARK: - Paths

    private func storageRootURL() -> URL {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let bundleId = Bundle.main.bundleIdentifier ?? "default_bundle"
        return urls[0].appendingPathComponent(bundleId).appendingPathComponent("JSONStorage")
    }

    /// 将 `key` 解析为具体文件路径；拒绝空路径与含 `..` 的分段。
    private func fileURL(forKey key: String) -> URL? {
        let segments = sanitizedSegments(from: key)
        guard let last = segments.last else { return nil }
        var url = storageRootURL()
        for segment in segments.dropLast() {
            url = url.appendingPathComponent(segment)
        }
        return url.appendingPathComponent("\(last).json")
    }

    private func directoryURL(forKeyPrefix prefix: String) -> URL {
        let segments = sanitizedSegments(from: prefix)
        return segments.reduce(storageRootURL()) { $0.appendingPathComponent($1) }
    }

    private func sanitizedSegments(from key: String) -> [String] {
        key.split(separator: "/")
            .map(String.init)
            .filter { !$0.isEmpty && $0 != "." && $0 != ".." }
    }
}
