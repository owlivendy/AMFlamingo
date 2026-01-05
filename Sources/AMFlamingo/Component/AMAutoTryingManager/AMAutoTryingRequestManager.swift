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

/// ✅ Swift5.6+ 专用：解决 any Encodable 无法编码的核心工具
struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    
    /// 接收任意遵循 Encodable 的类型（包括 any Encodable）
    init(_ value: some Encodable) {
        _encode = value.encode
    }
    
    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
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
        // 转换为可存储的字典
        var requestDict: [String: Any] = [
            "identifier": request.identifier,
            "domain": request.domain,
            "path": request.path,
            "method": request.method.rawValue,
            "retryCount": request.retryCount
        ]
        if let params = request.params {
            requestDict["params"] = params
        }
        
        // 使用AMLocalJSONStorage保存请求
        AMLocalJSONStorage.shared.saveOC(requestDict,
                                       fileName: request.identifier,
                                       businessDir: businessDir,
                                       businessId: request.businessId,
                                       overwrite: true,
                                       permanent: true)
    }
    
    /// 从本地加载待处理请求
    private func loadPendingRequestsFromLocal() {
        // 获取所有永久保存的失败请求文件名
        let filePaths = AMLocalJSONStorage.shared.getAllPermanentFilePaths(businessDir: businessDir)
        
        print("AMAutoTryingRequestManager: Found \(filePaths.count) files in directory")
        
        // 加载本地未完成的请求
        for filePath in filePaths {
            print("AMAutoTryingRequestManager: Loading file: \(filePath)")
            
            if let dataDict = AMLocalJSONStorage.shared.loadOCPermanentDictionary(path: filePath) {
                print("AMAutoTryingRequestManager: Successfully loaded data from file: \(filePath)")
                
                // 解析请求数据
                if let identifier = dataDict["identifier"] as? String,
                   let domain = dataDict["domain"] as? String,
                   let path = dataDict["path"] as? String,
                   let methodRawValue = dataDict["method"] as? Int,
                   let retryCount = dataDict["retryCount"] as? Int {
                    
                    let method = HTTPMethod(rawValue: methodRawValue) ?? .get
                    let params = dataDict["params"] as? [String: Any]
                    
                    let request = AMAutoTryingInternalRequest(
                        identifier: identifier,
                        domain: domain,
                        path: path,
                        method: method,
                        params: params,
                        retryCount: retryCount
                    )
                    
                    tryingRequests.append(request)
                }
            } else {
                print("AMAutoTryingRequestManager: Failed to load file: \(filePath)")
            }
        }
    }
    
    /// 从本地删除请求
    /// - Parameter request: 要删除的请求
    private func deleteRequestFromLocal(_ request: AMAutoTryingInternalRequest) {
        AMLocalJSONStorage.shared.removePermanent(fileName: request.identifier, businessDir: businessDir, businessId: request.businessId)
    }
}
