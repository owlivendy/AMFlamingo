//
//  AMLogManager.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/7/2.
//  Copyright © 2025 shen xiaofei. All rights reserved.
//

import Foundation

// MARK: - 全局日志方法
public func AMLogDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    AMLogManager.shared.logDebug(message, file: file, function: function, line: line)
}

public func AMLogInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    AMLogManager.shared.logInfo(message, file: file, function: function, line: line)
}

public func AMLogWarn(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    AMLogManager.shared.logWarn(message, file: file, function: function, line: line)
}

public func AMLogError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    AMLogManager.shared.logError(message, file: file, function: function, line: line)
}

// MARK: - AMLogManager 类
public class AMLogManager {
    
    // MARK: - 单例
    public static let shared = AMLogManager()
    
    // 日志时间格式化器
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    private init() {}
    
    // MARK: - 日志方法
    public func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let timeStr = dateFormatter.string(from: Date())
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("\(timeStr) [D] [\(fileName):\(line)] \(function): \(message)")
    }
    
    public func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let timeStr = dateFormatter.string(from: Date())
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("\(timeStr) [I] [\(fileName):\(line)] \(function): \(message)")
    }
    
    public func logWarn(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let timeStr = dateFormatter.string(from: Date())
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("\(timeStr) [W] [\(fileName):\(line)] \(function): \(message)")
    }
    
    public func logError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let timeStr = dateFormatter.string(from: Date())
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("\(timeStr) [E] [\(fileName):\(line)] \(function): \(message)")
    }
}
