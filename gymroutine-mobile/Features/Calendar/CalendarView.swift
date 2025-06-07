//
//  CalendarView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/12/27.
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct CalendarView: View {
    
    @StateObject private var viewModel = CalendarViewModel()
    @State private var routineFlg = false
    private let analyticsService = AnalyticsService.shared
    
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
    
    var body: some View {
        VStack(spacing: 0) {
            headerBox()
            
            calendarBox
                .onAppear {
                    viewModel.fetchUserRoutine()
                }
            
            contentBox
        }
        .background(Color.gray.opacity(0.1))
        .sheet(isPresented: $routineFlg) {
            Text("ルーティーン追加画面を\nここに作成")
        }
        .onAppear {
            // Log screen view
            analyticsService.logScreenView(screenName: "Calendar")
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
                calendarWeekRow(week: week)
            }
        }
        .vAlign(.center)
    }
    
    // 주간 행을 렌더링하는 함수
    @ViewBuilder
    private func calendarWeekRow(week: [Date?]) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { index in
                calendarDayCell(weekIndex: index, day: index < week.count ? week[index] : nil)
            }
        }
    }
    
    // 일별 셀을 렌더링하는 함수
    @ViewBuilder
    private func calendarDayCell(weekIndex: Int, day: Date?) -> some View {
        Group {
            if let validDay = day {
                dayCellContent(weekIndex: weekIndex, validDay: validDay)
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(2)
    }
    
    // 유효한 날짜의 셀 내용을 렌더링하는 함수
    @ViewBuilder
    private func dayCellContent(weekIndex: Int, validDay: Date) -> some View {
        let workouts = viewModel.getWorkoutsForWeekday(index: weekIndex)
        let hasCompleted = viewModel.hasCompletedWorkout(on: validDay)
        
        VStack {
            // 날짜 숫자
            Text("\(Calendar.current.component(.day, from: validDay))")
                .foregroundColor(hasCompleted ? .blue : .primary)
            
            // 도트 표시기
            dayIndicatorDots(workouts: workouts, hasCompleted: hasCompleted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(hasCompleted ? Color.green.opacity(0.1) : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(validDay.isSameDay(as: viewModel.selectedDate) ? .main : .clear, lineWidth: 2)
        )
        .onTapGesture {
            viewModel.selectedDate = validDay
            // Log calendar interaction
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            analyticsService.logCalendarInteraction(
                interactionType: "date_selected",
                dateSelected: formatter.string(from: validDay)
            )
        }
    }
    
    // 도트 인디케이터를 렌더링하는 함수
    @ViewBuilder
    private func dayIndicatorDots(workouts: [Workout], hasCompleted: Bool) -> some View {
        HStack(spacing: 2) {
            // 예정된 운동 표시 (빨간색 점)
            ForEach(0..<min(workouts.count, 3), id: \.self) { _ in
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
            }
            
            // 완료된 운동 표시 (녹색 점)
            if hasCompleted {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(height: 6)
    }
    
    private var contentBox: some View {
        VStack {
            dateHeaderView
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    scheduledWorkoutsSection
                    
                    completedWorkoutsSection
                }
                .padding()
            }
            .vAlign(.top)
        }
    }
    
    private var dateHeaderView: some View {
        Text(viewModel.selectedDate.toMonthDayWeekdayString())
            .font(.headline)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .hAlign(.leading)
            .background(Color.gray.opacity(0.2))
    }
    
    private var scheduledWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("予定されているワークアウト")
                .font(.headline)
                .foregroundColor(.primary)
            
            let weekdayIndex = Calendar.current.component(.weekday, from: viewModel.selectedDate) - 1
            let scheduledWorkouts = viewModel.getWorkoutsForWeekday(index: weekdayIndex)
            
            scheduledWorkoutsContent(workouts: scheduledWorkouts)
        }
    }
    
    @ViewBuilder
    private func scheduledWorkoutsContent(workouts: [Workout]) -> some View {
        if workouts.isEmpty {
            Text("予定されているワークアウトなし")
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
        } else {
            ForEach(workouts, id: \.id) { workout in
                scheduledWorkoutRow(workout: workout)
            }
        }
    }
    
    private func scheduledWorkoutRow(workout: Workout) -> some View {
        NavigationLink(destination: WorkoutDetailView(viewModel: WorkoutDetailViewModel(workout: workout))) {
            WorkoutCell(
                workoutName: workout.name,
                exerciseImageName: workout.exercises.first?.key,
                count: workout.exercises.count
            )
        }
        .buttonStyle(.plain)
    }
    
    private var completedWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("完了したワークアウト")
                .font(.headline)
                .foregroundColor(.primary)
            
            let completedWorkouts = viewModel.getCompletedWorkoutsForDate(viewModel.selectedDate)
            
            completedWorkoutsContent(results: completedWorkouts)
        }
    }
    
    @ViewBuilder
    private func completedWorkoutsContent(results: [WorkoutResult]) -> some View {
        if results.isEmpty {
            Text("完了したワークアウトなし")
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
        } else {
            ForEach(results, id: \.id) { result in
                CompletedWorkoutCell(
                    result: result, 
                    workoutName: viewModel.getWorkoutName(for: result)
                )
            }
        }
    }
}

#Preview {
    CalendarView()
}
