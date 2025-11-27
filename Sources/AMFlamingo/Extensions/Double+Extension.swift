//
//  Double+Extension.swift
//  AMFlamingo
//
//  Created by shen xiaofei on 2025/6/30.
//  Copyright © 2025 shen xiaofei. All rights reserved.
//

public extension Double {
    func format(_ format: String) -> String {
        let date = Date(timeIntervalSince1970: self)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
}
