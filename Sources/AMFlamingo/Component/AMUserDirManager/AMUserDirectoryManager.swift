//
//  AMUserDirManager.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/8/21.
//  Copyright © 2025 shen xiaofei. All rights reserved.
//


/// iOS 用户目录管理器，用于获取 tmp/caches/documentation 目录并管理用户标识
@objcMembers
class AMUserDirectoryManager: NSObject {
    // 单例实例（可选，也可按需创建实例）
    static let shared = AMUserDirectoryManager()
    
    // 用户信息存储
    private var username: String?
    private var userId: String?
    // 默认用户标识（未设置用户名和用户ID时使用）
    private let defaultUserIdentifier = "guest"
    
    /// 设置用户信息（用户名和用户ID）
    /// - Parameters:
    ///   - username: 用户名（可选，为空则不更新）
    ///   - userId: 用户ID（可选，为空则不更新）
    func setUserInfo(username: String? = nil, userId: String? = nil) {
        if let validUsername = username?.trimmingCharacters(in: .whitespacesAndNewlines), !validUsername.isEmpty {
            self.username = validUsername
        }
        if let validUserId = userId?.trimmingCharacters(in: .whitespacesAndNewlines), !validUserId.isEmpty {
            self.userId = validUserId
        }
    }
    
    /// 获取    /// 获取指定类型的用户目录（tmp/caches/documentation）
    /// - Parameter directoryType: 目录类型（tmp/caches/documentation）
    /// - Returns: 目录路径 URL（成功）或 nil（失败）
    func getUserDirectory(for directoryType: DirectoryType) -> URL? {
        // 1. 获取系统基础目录
        guard let baseDir = getBaseDirectory(for: directoryType) else {
            print("❌ 无法获取系统基础目录（类型：\(directoryType.rawValue)）")
            return nil
        }
        
        // 2. 生成用户标识（username_userId 格式，未设置则用 guest）
        let userIdentifier = getValidUserIdentifier()
        
        // 3. 拼接用户专属目录路径（基础目录/用户标识）
        let userDir = baseDir.appendingPathComponent(userIdentifier, isDirectory: true)
        
        // 4. 目录不存在则创建（处理创建失败场景）
        do {
            try FileManager.default.createDirectory(
                at: userDir,
                withIntermediateDirectories: true,  // 自动创建中间目录
                attributes: nil
            )
            print("✅ 成功获取/创建用户目录：\(userDir.path)")
            return userDir
        } catch {
            print("❌ 创建用户目录失败（路径：\(userDir.path)），错误：\(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - 私有辅助方法
private extension AMUserDirectoryManager {
    /// 生成有效的用户标识（username_userId 或 guest）
    func getValidUserIdentifier() -> String {
        guard let username = username, let userId = userId,
              !username.isEmpty, !userId.isEmpty else {
            return defaultUserIdentifier
        }
        return "\(username)_\(userId)"
    }
    
    /// 获取系统基础目录（tmp/caches/documentation）
    func getBaseDirectory(for directoryType: DirectoryType) -> URL? {
        let fileManager = FileManager.default
        let searchPathDirectory: FileManager.SearchPathDirectory
        
        switch directoryType {
        case .tmp:
            return fileManager.temporaryDirectory  // 系统临时目录
        case .caches:
            searchPathDirectory = .cachesDirectory
        case .documentation:
            searchPathDirectory = .documentDirectory
        }
        
        // 从用户域获取目录（iOS 推荐使用 userDomainMask）
        return fileManager.urls(
            for: searchPathDirectory,
            in: .userDomainMask
        ).first
    }
}

// MARK: - 目录类型枚举
/// 支持的用户目录类型
@objc enum DirectoryType: Int {
    case tmp = 0
    case caches
    case documentation
    
    var descripation:String {
        switch self {
        case .tmp:
            return "临时目录"
        case .caches:
            return "缓存目录"
        case .documentation:
            return "文档目录"
        }
    }
}
