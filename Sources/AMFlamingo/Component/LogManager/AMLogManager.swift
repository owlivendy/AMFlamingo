//
//  AMLogManager.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/7/2.
//  Copyright © 2025 shen xiaofei. All rights reserved.
//

import Foundation

// MARK: - 全局日志方法
public func CHLogDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    AMLogManager.shared.logDebug(message, file: file, function: function, line: line)
}

public func CHLogInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    AMLogManager.shared.logInfo(message, file: file, function: function, line: line)
}

public func CHLogWarn(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    AMLogManager.shared.logWarn(message, file: file, function: function, line: line)
}

public func CHLogError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    AMLogManager.shared.logError(message, file: file, function: function, line: line)
}

// MARK: - AMLogManager 类
public class AMLogManager {
    
    // MARK: - 单例
    public static let shared = AMLogManager()
    
    private init() {}
    
    // MARK: - 日志方法
    public func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("[\(fileName):\(line)] \(function): \(message)")
    }
    
    public func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("[\(fileName):\(line)] \(function): \(message)")
    }
    
    public func logWarn(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("[\(fileName):\(line)] \(function): \(message)")
    }
    
    public func logError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("[\(fileName):\(line)] \(function): \(message)")
    }
}
