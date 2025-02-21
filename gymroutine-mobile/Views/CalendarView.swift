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
    @State private var routineFlg = false
    
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
    
    var body: some View {
        VStack(spacing: 0) {
            headerBox()
            
            calendarBox
            
            contentBox
        }
        .background(Color.gray.opacity(0.1))
        .sheet(isPresented: $routineFlg) {
            Text("ルーティーン追加画面を\nここに作成")
        }
    }
}

//MARK: Views
extension CalendarView {
    @ViewBuilder
    private func headerBox() -> some View {
        if let selectedMonth = viewModel.selectedMonth {
            Text(selectedMonth.toYearMonthString())
                .font(.title2.bold())
                .padding()
                .hAlign(.center)
                .overlay(alignment: .trailing) {
                    Button(action: {
                        routineFlg.toggle()
                    }, label: {
                        Image(systemName: "plus")
                            .imageScale(.large).bold()
                            .padding(.trailing)
                    })
                }
        }
    }
    
    private var calendarBox: some View {
        VStack {
            
            LazyVGrid(columns: Array(repeating: GridItem(), count: 7)) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                }
            }
            
            Divider()
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(viewModel.months, id: \.self) { month in
                        CalendarGridView(month.generateCalendarDays())
                            .containerRelativeFrame([.horizontal, .vertical])
                            .id(month)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $viewModel.selectedMonth)
            .vAlign(.center)
            .onChange(of: viewModel.selectedMonth) {
                viewModel.onChangeMonth(viewModel.selectedMonth)
            }
        }
    }
    
    @ViewBuilder
    private func CalendarGridView(_ days: [Date?]) -> some View {
        VStack(spacing: 4) {
            ForEach(Array(days.chunked(into: 7)), id: \.self) { week in
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { index in
                        Group {
                            if index < week.count, let validDay = week[index] {
                                Text("\(Calendar.current.component(.day, from: validDay))")
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(validDay.isSameDay(as: viewModel.selectedDate) ? .main : .clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        viewModel.selectedDate = validDay
                                    }
                            } else {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                        .padding(2)
                    }
                }
            }
        }
        .vAlign(.center)
    }
    
    private var contentBox: some View {
        VStack {
            Text(viewModel.selectedDate.toMonthDayWeekdayString())
                .font(.headline)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .hAlign(.leading)
                .background(Color.gray.opacity(0.2))
            
            ScrollView(showsIndicators: false) {
                VStack {
                    Text("ここにWorkoutCellを配置")
                    Text("ここにWorkoutCellを配置")
                    Text("ここにWorkoutCellを配置")
                }
            }
            .vAlign(.top)
        }
    }
}

#Preview {
    CalendarView()
}
