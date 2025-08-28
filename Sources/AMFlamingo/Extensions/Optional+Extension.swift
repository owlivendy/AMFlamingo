//
//  Optional+Extension.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/6/18.
//  Copyright © 2025 shen xiaofei. All rights reserved.
//

extension Optional where Wrapped: Collection {
    var valueNotEmpty: Wrapped? {
        get {
            switch self {
            case .none:
                return nil
            case .some(let value):
                return value.isEmpty ? nil : value
            }
        }
    }
    
    var isNullOrEmpty: Bool {
        get {
            switch self {
            case .none:
                return true
            case .some(let value):
                return value.isEmpty
            }
        }
    }
}

