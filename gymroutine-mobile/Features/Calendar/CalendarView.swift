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
        let workouts = viewModel.getWorkoutsForDate(validDay)
        let hasCompleted = viewModel.hasCompletedWorkout(on: validDay)
        let hasScheduled = viewModel.hasScheduledWorkout(on: validDay)
        
        VStack(spacing: 2) {
            // 날짜 숫자
            Text("\(Calendar.current.component(.day, from: validDay))")
                .font(.system(size: 14, weight: hasScheduled || hasCompleted ? .bold : .regular))
                .foregroundColor(hasCompleted ? .blue : .primary)
            
            // 도트 표시기
            dayIndicatorDots(workouts: workouts, hasCompleted: hasCompleted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColorForDay(hasScheduled: hasScheduled, hasCompleted: hasCompleted))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(validDay.isSameDay(as: viewModel.selectedDate) ? .main : .clear, lineWidth: 2)
        )
        .onTapGesture {
            viewModel.selectedDate = validDay
        }
    }
    
    // 날짜 셀의 배경색을 결정하는 함수
    private func backgroundColorForDay(hasScheduled: Bool, hasCompleted: Bool) -> Color {
        if hasCompleted {
            return Color.green.opacity(0.2)
        }
        return Color.clear
    }
    
    // 도트 인디케이터를 렌더링하는 함수
    @ViewBuilder
    private func dayIndicatorDots(workouts: [Workout], hasCompleted: Bool) -> some View {
        HStack(spacing: 1) {
            // 스케줄 타입별 다른 색상의 점으로 표시
            ForEach(Array(workouts.prefix(3).enumerated()), id: \.offset) { index, workout in
                Circle()
                    .fill(colorForScheduleType(workout.schedule.type))
                    .frame(width: 5, height: 5)
            }
            
            // 더 많은 워크아웃이 있으면 "..." 표시
            if workouts.count > 3 {
                Text("...")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            
            // 완료된 운동 표시 (녹색 체크 마크)
            if hasCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.green)
            }
        }
        .frame(height: 12)
    }
    
    // 스케줄 타입별 색상 반환
    private func colorForScheduleType(_ type: WorkoutScheduleType) -> Color {
        return .red
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
            Text("予定されたワークアウト")
                .font(.headline)
                .foregroundColor(.primary)
            
            let scheduledWorkouts = viewModel.getWorkoutsForDate(viewModel.selectedDate)
            
            scheduledWorkoutsContent(workouts: scheduledWorkouts)
        }
    }
    
    @ViewBuilder
    private func scheduledWorkoutsContent(workouts: [Workout]) -> some View {
        if workouts.isEmpty {
            Text("予定されたワークアウトなし")
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
            VStack {
                WorkoutCell(
                    workoutName: workout.name,
                    exerciseImageName: workout.exercises.first?.key,
                    count: workout.exercises.count
                )
                
                // 스케줄 및 진행 정보 표시
                HStack {
                    scheduleTypeLabel(workout.schedule.type)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        // 남은 기간 정보
                        if let remainingDuration = viewModel.getRemainingDuration(for: workout) {
                            Text(remainingDuration)
                                .font(.caption)
                                .foregroundColor(remainingDuration.contains("期限切れ") || remainingDuration.contains("完了") ? .red : .secondary)
                        }
                        
                        // 진행 상황 (총 횟수가 설정된 경우)
                        if let progress = viewModel.getWorkoutProgress(for: workout) {
                            Text("\(progress.completed)/\(progress.total!)回")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
        .buttonStyle(.plain)
    }
    
    // 스케줄 타입 라벨
    private func scheduleTypeLabel(_ type: WorkoutScheduleType) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(colorForScheduleType(type))
                .frame(width: 8, height: 8)
            
            Text(type.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // 기간 정보 표시 (사용하지 않으므로 제거하거나 간소화)
    private func durationInfo(_ duration: WorkoutDuration) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let totalSessions = duration.totalSessions {
                Text("총 \(totalSessions)회")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let weeks = duration.weeks {
                Text("\(weeks)주간")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let endDate = duration.endDate {
                Text("~\(endDate.formatted(.dateTime.month().day()))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
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
