//
//  URLParameterEncoder.swift
//  Flamingo
//
//  Created by xiaofei shen on 2025/9/8.
//

import Foundation

/// URL 参数编码工具：拆分URL为URLQueryItem数组，仅编码参数值（value），保留参数键（name）不编码
struct URLQueryItemEncoder {
    /// 核心函数：仅编码 URL 中 URLQueryItem 的值，返回编码后的 URL 对象
    /// - Parameter urlString: 原始 URL 字符串（可含未编码的参数值，如中文、特殊字符）
    /// - Returns: 仅参数值编码后的 URL 对象，失败返回 nil
    static func encodeOnlyQueryItemValues(in urlString: String) -> URL? {
        // 1. 拆分 URL 组件（query 类型为 [URLQueryItem]?）
        guard let (scheme, host, path, queryItems, fragment) = splitURLComponents(from: urlString) else {
            print("⚠️ URL 结构解析失败，无法编码参数值")
            return nil
        }
        
        // 2. 重新拼接 URL 各部分
        guard let encodedURL = buildEncodedURL(
            scheme: scheme,
            host: host,
            path: path,
            queryItems: queryItems,
            fragment: fragment
        ) else {
            print("⚠️ 编码后组件无法拼接为合法 URL")
            return nil
        }
        
        return encodedURL
    }
    
    // MARK: - 核心调整：拆分 URL 为 [URLQueryItem]? 类型的 query
    private static func splitURLComponents(from urlString: String) -> (
        scheme: String?,
        host: String?,
        path: String?,
        queryItems: [URLQueryItem]?,
        fragment: String?
    )? {
        // 优先用系统 URLComponents 解析（自动转为 URLQueryItem 数组）
        if let components = URLComponents(string: urlString) {
            return (
                scheme: components.scheme,
                host: components.host,
                path: components.path,
                queryItems: components.queryItems, // 直接获取 [URLQueryItem]? 类型
                fragment: components.fragment
            )
        }
        
        // 系统解析失败时，手动拆分非标准 URL 并转为 URLQueryItem 数组
//        return manualSplitToQueryItems(urlString)
        return nil
    }
    
    // 手动拆分非标准 URL（如 "example.com/path?name=张三&age=25#tag"），转为 URLQueryItem 数组
    private static func manualSplitToQueryItems(_ urlString: String) -> (
        scheme: String?,
        host: String?,
        path: String?,
        queryItems: [URLQueryItem]?,
        fragment: String?
    ) {
        var remaining = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        var scheme: String? = nil
        var host: String? = nil
        var path: String? = nil
        var queryItems: [URLQueryItem]? = nil
        var fragment: String? = nil
        
        // 1. 拆分片段（#后部分）
        if let fragmentSepIndex = remaining.firstIndex(of: "#") {
            let fragmentStart = remaining.index(after: fragmentSepIndex)
            fragment = String(remaining[fragmentStart...])
            remaining = String(remaining[..<fragmentSepIndex])
        }
        
        // 2. 拆分查询参数（?后部分）并转为 URLQueryItem 数组
        if let querySepIndex = remaining.firstIndex(of: "?") {
            let queryStart = remaining.index(after: querySepIndex)
            let queryString = String(remaining[queryStart...])
            remaining = String(remaining[..<querySepIndex])
            
            // 将 query 字符串拆分为 key=value 对，转为 URLQueryItem
            queryItems = queryString.components(separatedBy: "&")
                .filter { !$0.isEmpty } // 过滤空参数
                .map { param in
                    let keyValue = param.components(separatedBy: "=")
                    let name = keyValue.first ?? param // 参数键（name）
                    let value = keyValue.count > 1 ? keyValue.dropFirst().joined(separator: "=") : nil // 参数值（value，支持含=的场景）
                    return URLQueryItem(name: name, value: value)
                }
        }
        
        // 3. 拆分协议（如 https://）
        if let schemeSepRange = remaining.range(of: "://") {
            scheme = String(remaining[..<schemeSepRange.lowerBound]) + "://"
            remaining = String(remaining[schemeSepRange.upperBound...])
        }
        
        // 4. 拆分域名和路径
        if let pathStartIndex = remaining.firstIndex(of: "/") {
            host = String(remaining[..<pathStartIndex])
            path = String(remaining[pathStartIndex...])
        } else {
            host = remaining
            path = ""
        }
        
        return (scheme: scheme, host: host, path: path, queryItems: queryItems, fragment: fragment)
    }
    
    // MARK: - 拼接编码后的 URL 对象
    private static func buildEncodedURL(
        scheme: String?,
        host: String?,
        path: String?,
        queryItems: [URLQueryItem]?,
        fragment: String?
    ) -> URL? {
        // 用 URLComponents 拼接，确保 URL 结构合法
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path ?? ""
        components.queryItems = queryItems // 直接传入编码后的 URLQueryItem 数组
        components.fragment = fragment
        
        return components.url
    }
}
