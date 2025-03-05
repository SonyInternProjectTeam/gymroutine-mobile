//
//  CalendarViewModel.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2025/02/03
//  
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct TestWorkout: Decodable {
    @DocumentID var id: String?
    let uuid: String
    let name: String
    let createdAt: Date
    let scheduledDays: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case name
        case createdAt = "CreatedAt"
        case scheduledDays = "ScheduledDays"
    }
}

@MainActor
final class CalendarViewModel: ObservableObject {
    
    @Published var months: [Date] = []  //月ごとのDate情報
    @Published var selectedDate: Date = Date()  //選択されている日にち
    @Published var selectedMonth: Date? //Viewに表示されている月
    @Published var workoutsByWeekday: [String: [TestWorkout]] = [:]
    
    private let calendar: Calendar = .current
    private let workoutService = WorkoutService()
    private let userManager = UserManager.shared
    
    let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    init() {
        self.months = (-2...2).compactMap { calendar.date(byAdding: .month, value: $0, to: selectedDate) }
        self.selectedMonth = selectedDate
        fetchUserRoutine()
    }
    
    func fetchUserRoutine() {
        guard let uid = userManager.currentUser?.uid else {
            print("[ERROR] Currentuidが取得できません")
            return
        }
        
        Task {
            guard let userWorkouts = await workoutService.fetchUserWorkouts(uid: uid) else {
                return
            }
            self.categorizeWorkoutsByWeekday(userWorkouts)
        }
    }
    
    // userが設定したScheduleDaysから、曜日ごとにカテゴライズ
    private func categorizeWorkoutsByWeekday(_ workouts: [TestWorkout]) {
        var categorizedWorkouts: [String: [TestWorkout]] = [:]
        
        for workout in workouts {
            for scheduledDay in workout.scheduledDays {
                categorizedWorkouts[scheduledDay, default: []].append(workout)
            }
        }
        
        self.workoutsByWeekday = categorizedWorkouts
    }
    
    //カレンダーがスクロールすると呼び出される
    func onChangeMonth(_ month: Date?) {
        guard let month = month else { return }
        
        print("[DEBUG] ここで「\(month.formatted(.dateTime.year().month()))」のDB取得ロジックを呼び出し")
        checkAndLoadMoreMonths(for: month)
    }
    
    // スクロール時に前後2ヶ月が確保されるように管理
    func checkAndLoadMoreMonths(for monthDate: Date) {
        if let firstIndex = months.firstIndex(of: monthDate),
           firstIndex == 1 { // 先頭から2番目が表示されたら先月を追加
            loadPreviousMonth()
        }
        
        if let lastIndex = months.firstIndex(of: monthDate),
           lastIndex == months.count - 2 { // 末尾から2番目が表示されたら翌月を追加
            loadNextMonth()
        }
    }
    
    // months配列に先月を追加
    func loadPreviousMonth() {
        if let firstMonth = months.first,
           let prevMonth = calendar.date(byAdding: .month, value: -1, to: firstMonth) {
            months.insert(prevMonth, at: 0)
        }
    }

    // months配列に来月を追加
    func loadNextMonth() {
        if let lastMonth = months.last,
           let nextMonth = calendar.date(byAdding: .month, value: 1, to: lastMonth) {
            months.append(nextMonth)
        }
    }
    
    //曜日indexからその曜日のWorkoutを取得（0 -> 日曜日, 1 -> 月曜日
    func getWorkoutsForWeekday(index: Int) -> [TestWorkout] {
        guard index >= 0, index < weekdays.count else { return [] }
        let weekday = weekdays[index]
        return workoutsByWeekday[weekday] ?? []
    }
}
