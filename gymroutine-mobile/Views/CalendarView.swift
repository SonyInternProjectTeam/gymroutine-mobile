//
//  CalendarView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/12/27.
//

import Foundation
import SwiftUI

// TODO : 仮のカレンダビュー

struct CalendarView: View {
    
    @StateObject private var viewModel = CalendarViewModel()
    var body: some View {
        VStack {
            Text("カレンダー")
                .font(.title)
                .padding()

            List {
                ForEach(generateDatesForCurrentMonth(), id: \.self) { date in
                    Text(formatDate(date))
                }
            }
        }
        .navigationTitle("Calendar")
    }

    private func generateDatesForCurrentMonth() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        let range = calendar.range(of: .day, in: .month, for: today)!

        return range.compactMap { day -> Date? in
            var components = calendar.dateComponents([.year, .month], from: today)
            components.day = day
            return calendar.date(from: components)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}
