//
//  AttributedStringLinkDetector.swift
//  Flamingo
//
//  Created by xiaofei shen on 2025/9/8.
//

import UIKit

class AttributedStringLinkDetector: NSObject {
    /// 检测结果模型：包含链接地址、对应字符范围、对应文本
    struct LinkResult {
        let url: URL                // 链接地址（统一转为URL）
        let range: NSRange          // 链接在字符串中的字符范围
        let text: String            // 链接对应的文本内容
    }
    
    /// 1. 判断 NSAttributedString 是否包含链接
    /// - Parameter attributedString: 待检测的富文本
    /// - Returns: 存在链接返回 true，否则 false
    static func hasLink(in attributedString: NSAttributedString) -> Bool {
        var hasLink = false
        // 遍历所有属性范围（NSRange从0到字符串长度）
        attributedString.enumerateAttributes(
            in: NSRange(location: 0, length: attributedString.length),
            options: []
        ) { attributes, _, stop in
            // 检查当前范围是否包含 link 属性
            if attributes[.link] != nil {
                hasLink = true
                stop.pointee = true // 找到后停止遍历，提高效率
            }
        }
        return hasLink
    }
    
    /// 2. 提取 NSAttributedString 中的所有链接（含位置信息）
    /// - Parameter attributedString: 待提取的富文本
    /// - Returns: 链接结果数组（LinkResult），无链接返回空数组
    static func extractAllLinks(from attributedString: NSAttributedString) -> [LinkResult] {
        var linkResults = [LinkResult]()
        
        attributedString.enumerateAttributes(
            in: NSRange(location: 0, length: attributedString.length),
            options: []
        ) { attributes, range, _ in
            // 1. 检查当前范围是否有 link 属性
            guard let linkValue = attributes[.link] else { return }
            
            // 2. 处理 link 值：可能是 URL 或 String，统一转为 URL
            let linkUrl: URL?
            if let url = linkValue as? URL {
                // 情况1：直接是 URL 类型（推荐存储方式）
                linkUrl = url
            } else if let urlString = linkValue as? String {
                // 情况2：是 String 类型（需转为 URL，注意处理非法字符串）
                linkUrl = URLQueryItemEncoder.encodeOnlyQueryItemValues(in: urlString)
//                linkUrl = URL(string: urlString)
            } else {
                // 情况3：不支持的类型（如其他对象），跳过
                print("⚠️ 不支持的 link 类型：\(type(of: linkValue))")
                return
            }
            
            // 3. 过滤非法 URL，生成结果模型
            guard let validUrl = linkUrl else {
                print("⚠️ 无效的链接地址：\(linkValue)（范围：\(range)）")
                return
            }
            // 获取链接对应的文本内容
            let linkText = attributedString.attributedSubstring(from: range).string
            // 添加到结果数组
            linkResults.append(LinkResult(
                url: validUrl,
                range: range,
                text: linkText
            ))
        }
        
        return linkResults
    }
    
    /// 3. 简化方法：仅提取所有链接地址（忽略位置信息）
    /// - Parameter attributedString: 待提取的富文本
    /// - Returns: 链接 URL 数组，无链接返回空数组
    static func extractLinkUrls(from attributedString: NSAttributedString) -> [URL] {
        let linkResults = extractAllLinks(from: attributedString)
        return linkResults.map { $0.url }
    }
}
