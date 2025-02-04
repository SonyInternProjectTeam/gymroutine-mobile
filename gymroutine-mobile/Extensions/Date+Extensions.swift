//
//  Date+Extensions.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2025/02/03
//  
//

import Foundation

extension Date {
    //対象の月の日付情報を取得
    func generateCalendarDays() -> [Date?] {
        let calendar = Calendar.current
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: self))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth)!

        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            days.append(calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth))
        }
        return days
    }
    
    // 同じ日付か判定
    func isSameDay(as otherDate: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, equalTo: otherDate, toGranularity: .day)
    }
    
    // Stringに変換・出力例：2025年2月
    func toYearMonthString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: self)
    }
    
    // Stringに変換・出力例：2月3日（月）
    func toMonthDayWeekdayString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日（EEE）"
        return formatter.string(from: self)
    }
}
