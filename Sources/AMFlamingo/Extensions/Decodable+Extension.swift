//
//  Decodable+Extension.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/6/19.
//  Copyright © 2025 shen xiaofei. All rights reserved.
//
import Foundation

public extension Decodable {
    static func from(json: [String: Any]) -> Self? {
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            let decoder = Foundation.JSONDecoder()
            return try decoder.decode(Self.self, from: data)
        } catch {
            print("解析失败: \(error)")
            return nil
        }
    }
}
