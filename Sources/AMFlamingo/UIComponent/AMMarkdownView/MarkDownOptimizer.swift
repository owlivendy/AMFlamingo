//
//  MarkDownOptimizer.swift
//  Flamingo
//
//  Created by xiaofei shen on 2025/9/8.
//

import UIKit

class MarkDownOptimizer: NSObject {
    static func optimizeMarkdown(_ input: String) -> String {
        return input
    }
    
    static func convertAsciiTablesToMarkdown(_ input: String) -> String {
        let lines = input.split(separator: "\n", omittingEmptySubsequences: false)
        var result = ""
        var tableBuffer: [String] = []
        var insideTable = false
        
        func flushTableBuffer() {
            guard !tableBuffer.isEmpty else { return }
            
            var rows: [[String]] = []
            for line in tableBuffer {
                if line.contains("│") {
                    // 用 omittingEmptySubsequences: false 保留空格列
                    let parts = line.split(separator: "│", omittingEmptySubsequences: false)
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                    
                    // 去掉首尾（边框两边的空）
                    let cleaned = parts.dropFirst().dropLast().map { String($0) }
                    
                    if !cleaned.isEmpty {
                        rows.append(Array(cleaned))
                    }
                }
            }
            
            if !rows.isEmpty {
                // 计算最大列数
                let columnCount = rows.map { $0.count }.max() ?? 0
                // 统一补齐空单元格
                let normalized = rows.map { row -> [String] in
                    var newRow = row
                    while newRow.count < columnCount {
                        newRow.append("")
                    }
                    return newRow
                }
                
                // 输出表格
                if let header = normalized.first {
                    result += "| " + header.joined(separator: " | ") + " |\n"
                    result += "|" + header.map { _ in "------" }.joined(separator: "|") + "|\n"
                }
                for row in normalized.dropFirst() {
                    result += "| " + row.joined(separator: " | ") + " |\n"
                }
            } else {
                result += tableBuffer.joined(separator: "\n") + "\n"
            }
            
            tableBuffer.removeAll()
        }
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let isBorderLine = trimmed.contains("─") || trimmed.contains("┼") || trimmed.contains("┌") || trimmed.contains("└")
            
            if isBorderLine || trimmed.contains("│") {
                insideTable = true
                tableBuffer.append(String(line))
            } else {
                if insideTable {
                    flushTableBuffer()
                    insideTable = false
                }
                result += line + "\n"
            }
        }
        
        if insideTable {
            flushTableBuffer()
        }
        
        return result
    }
}
