import Foundation

/// 用户目录管理器
public class AMUserDirManager {
    /// 单例
    public static let shared = AMUserDirManager()
    
    /// 当前用户唯一键
    public private(set) var userKey: String
    
    private let guestKey = "guest_user"
    private let userKeyKey = "AMUserDirManager.userKey"
    private let rootDirName = "com.amflamingo.userdirmanager"
    
    private init() {
        // 从 UserDefaults 读取用户唯一键，默认为 guest_user
        if let saved = UserDefaults.standard.string(forKey: userKeyKey), !saved.isEmpty {
            userKey = saved
        } else {
            userKey = guestKey
        }
    }
    
    /// 登录，设置用户唯一键
    public func login(userKey: String) {
        guard !userKey.isEmpty else { return }
        self.userKey = userKey
        UserDefaults.standard.set(userKey, forKey: userKeyKey)
    }
    
    /// 登出，重置为 guest_user
    public func logout() {
        self.userKey = guestKey
        UserDefaults.standard.set(guestKey, forKey: userKeyKey)
    }
    
    /// 获取用户专属 Document 目录
    public func userDocumentDirectory() -> URL {
        let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let rootDir = doc.appendingPathComponent(rootDirName, isDirectory: true)
        let userDir = rootDir.appendingPathComponent(userKey, isDirectory: true)
        createIfNeeded(userDir)
        return userDir
    }
    /// 获取用户专属 Cache 目录
    public func userCacheDirectory() -> URL {
        let cache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let rootDir = cache.appendingPathComponent(rootDirName, isDirectory: true)
        let userDir = rootDir.appendingPathComponent(userKey, isDirectory: true)
        createIfNeeded(userDir)
        return userDir
    }
    /// 获取用户专属 Tmp 目录
    public func userTmpDirectory() -> URL {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let rootDir = tmp.appendingPathComponent(rootDirName, isDirectory: true)
        let userDir = rootDir.appendingPathComponent(userKey, isDirectory: true)
        createIfNeeded(userDir)
        return userDir
    }
    
    /// 创建目录（如果不存在）
    private func createIfNeeded(_ url: URL) {
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
    }
}
