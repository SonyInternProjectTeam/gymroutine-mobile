//
//  Int+Extensions.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2025/04/27
//  
//

import Foundation

extension Int {
    /// 秒数（Int）を「hh:mm:ss」または「mm:ss」形式にフォーマットして返す
    var formattedDuration: String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = self % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
