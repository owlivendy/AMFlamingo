//
//  String+Extension.swift
//  AMFlamingo
//
//  Created by meotech on 2025/11/12.
//

import Foundation

public enum FlagSize {
    case size_40x30
    
    var size: (width:Int, height:Int) {
        switch self {
        case .size_40x30:
            return (40, 30)
        }
    }
}

public extension String {
    
    func createCoutryIconUrl(with flagSize: FlagSize = .size_40x30, ext: String = "png") -> String {
        return "https://flagcdn.com/\(flagSize.size.width)x\(flagSize.size.height)/\(self.lowercased()).\(ext)"
    }
    
}
