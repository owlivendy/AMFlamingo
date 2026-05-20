//
//  AMAutoTryingRequestManager.swift
//  AMFlamingo
//
//  Created by meotech on 2025/12/31.
//  Copyright © 2025 吕欢. All rights reserved.
//

import Foundation

/// HTTP请求方法枚举
public enum HTTPMethod: Int {
    case get
    case post
    case put
    case delete
}

/// 重试请求模型
public class AMAutoTryingRequest {
    public var domain: String
    public var path: String
    public var method: HTTPMethod
    ///请求参数
    public var params: [String: Any]?
    
    public init(domain: String, path: String, method: HTTPMethod, params: [String: Any]?) {
        self.domain = domain
        self.path = path
        self.method = method
        self.params = params
    }
}

/// 内部重试请求模型
open class AMAutoTryingInternalRequest {
    public let identifier: String
    public let domain: String
    public let path: String
    public let method: HTTPMethod
    public let params: [String: Any]?
    public var retryCount: Int
    
    public var businessId: String {
        let combinedString = "\(domain)\(path)"
        return combinedString.md5()
    }
    
    public init(identifier: String = UUID().uuidString, domain: String, path: String, method: HTTPMethod, params: [String: Any]?, retryCount: Int = 0) {
        self.identifier = identifier
        self.domain = domain
        self.path = path
        self.method = method
        self.params = params
        self.retryCount = retryCount
    }

    fileprivate func jsonStorageKey(businessDir: String) -> String {
        "\(businessDir)/\(businessId)/\(identifier)"
    }
}

/// 落盘用的 Codable 模型（`params` 以 JSON 数据保存）
private struct AMAutoTryingPersistedRequest: Codable {
    let identifier: String
    let domain: String
    let path: String
    let method: Int
    let retryCount: Int
    let paramsJSON: Data?

    init(_ request: AMAutoTryingInternalRequest) {
        identifier = request.identifier
        domain = request.domain
        path = request.path
        method = request.method.rawValue
        retryCount = request.retryCount
        if let params = request.params, JSONSerialization.isValidJSONObject(params) {
            paramsJSON = try? JSONSerialization.data(withJSONObject: params)
        } else {
            paramsJSON = nil
        }
    }

    func asInternalRequest() -> AMAutoTryingInternalRequest {
        let method = HTTPMethod(rawValue: method) ?? .get
        let params: [String: Any]?
        if let data = paramsJSON {
            params = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        } else {
            params = nil
        }
        return AMAutoTryingInternalRequest(
            identifier: identifier,
            domain: domain,
            path: path,
            method: method,
            params: params,
            retryCount: retryCount
        )
    }
}

/// 自动重试请求管理器
open class AMAutoTryingRequestManager {
    /// 单例实例
    public static let shared = AMAutoTryingRequestManager()
    
    /// 常量定义
    private let businessDir = "AutoTringRequest"
    
    /// 重试请求队列
    private var tryingRequests = [AMAutoTryingInternalRequest]()
    
    /// 是否正在请求
    private var isRequesting = false
    
    /// 网络问题重试计数
    private var netProblemTryingCount = 0
    
    /// 私有初始化方法，防止外部创建实例
    private init() {}
    
    /// 添加重试请求
    /// - Parameter request: 要添加的请求
    public func addTryingRequest(_ request: AMAutoTryingRequest) {
        guard !request.domain.isEmpty, !request.path.isEmpty else {
            return
        }
        
        // 将AMAutoTryingRequest转换为AMAutoTryingInternalRequest
        let params = request.params
        let internalRequest = AMAutoTryingInternalRequest(
            domain: request.domain,
            path: request.path,
            method: request.method,
            params: params,
            retryCount: 0
        )
        
        // 保存到本地
        saveRequestToLocal(internalRequest)
        
        // 添加到请求队列
        tryingRequests.append(internalRequest)
        
        // 尝试请求
        tryNextRequest()
    }
    
    /// 启动请求管理器
    public func start() {
        print("AMAutoTryingRequestManager: Starting request manager")
        
        // 加载本地未完成的请求
        loadPendingRequestsFromLocal()
        
        // 开始请求
        tryNextRequest()
    }
    
    /// 尝试下一个请求
    private func tryNextRequest() {
        // 检查是否有请求正在进行
        guard !isRequesting, !tryingRequests.isEmpty else {
            return
        }
        
        // 获取第一个请求
        let request = tryingRequests.first!
        
        // 开始请求
        startRequest(request)
    }
    
    /// 开始请求
    /// - Parameter request: 要执行的请求
    private func startRequest(_ request: AMAutoTryingInternalRequest) {
        isRequesting = true
        
        // 调用抽象方法，由子类实现具体的网络请求逻辑
        performRequest(request) { [weak self] success in
            guard let self = self else { return }
            
            self.isRequesting = false
            
            if success {
                self.netProblemTryingCount = 0
                // 请求成功，删除请求
                print("AMAutoTryingRequestManager: 请求成功，删除请求\(request.params ?? [:])")
                
                self.deleteTryingRequest(request)
                // 继续下一个请求
                self.tryNextRequest()
                return
            }
            
            // 请求失败，处理重试逻辑
            self.handleRequestFailure(request)
        }
    }
    
    /// 执行网络请求（抽象方法，由子类实现）
    /// - Parameters:
    ///   - request: 要执行的请求
    ///   - completion: 请求完成回调
    open func performRequest(_ request: AMAutoTryingInternalRequest, completion: @escaping (Bool) -> Void) {
        // 默认实现，子类必须重写
        fatalError("Subclasses must override performRequest method")
    }
    
    /// 处理请求失败
    /// - Parameter request: 失败的请求
    private func handleRequestFailure(_ request: AMAutoTryingInternalRequest) {
        // 非网络问题，重试次数+1
        request.retryCount += 1
        
        if request.retryCount > 5 {
            // 重试次数超过5次，删除请求
            print("AMAutoTryingRequestManager: 非网络问题，重试次数已经大于5次，删除请求\(request.params ?? [:])")
            deleteTryingRequest(request)
        } else {
            // 更新本地缓存
            print("AMAutoTryingRequestManager: 更新了本地缓存\(request.params ?? [:])")
            saveRequestToLocal(request)
        }
        
        // 固定延迟5秒后继续下一个请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.tryNextRequest()
        }
    }
    
    /// 删除重试请求
    /// - Parameter request: 要删除的请求
    private func deleteTryingRequest(_ request: AMAutoTryingInternalRequest) {
        // 从数组中删除
        if let index = tryingRequests.firstIndex(where: { $0.identifier == request.identifier }) {
            tryingRequests.remove(at: index)
        }
        
        // 删除本地缓存
        deleteRequestFromLocal(request)
    }
    
    /// 保存请求到本地
    /// - Parameter request: 要保存的请求
    private func saveRequestToLocal(_ request: AMAutoTryingInternalRequest) {
        let key = request.jsonStorageKey(businessDir: businessDir)
        AMJSONStorage.shared.save(AMAutoTryingPersistedRequest(request), key: key)
    }
    
    /// 从本地加载待处理请求
    private func loadPendingRequestsFromLocal() {
        let filePaths = AMJSONStorage.shared.storedFileURLs(keyPrefix: businessDir)

        print("AMAutoTryingRequestManager: Found \(filePaths.count) files in directory")

        for filePath in filePaths {
            print("AMAutoTryingRequestManager: Loading file: \(filePath)")
            guard let data = try? Data(contentsOf: filePath),
                  let payload = try? JSONDecoder().decode(AMAutoTryingPersistedRequest.self, from: data) else {
                print("AMAutoTryingRequestManager: Failed to load file: \(filePath)")
                continue
            }
            print("AMAutoTryingRequestManager: Successfully loaded data from file: \(filePath)")
            tryingRequests.append(payload.asInternalRequest())
        }
    }
    
    /// 从本地删除请求
    /// - Parameter request: 要删除的请求
    private func deleteRequestFromLocal(_ request: AMAutoTryingInternalRequest) {
        AMJSONStorage.shared.remove(key: request.jsonStorageKey(businessDir: businessDir))
    }
}
