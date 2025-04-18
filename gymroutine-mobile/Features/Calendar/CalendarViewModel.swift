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

@MainActor
final class CalendarViewModel: ObservableObject {
    
    @Published var months: [Date] = []  //月ごとのDate情報
    @Published var selectedDate: Date = Date()  //選択されている日にち
    @Published var selectedMonth: Date? //Viewに表示されている月
    @Published var workoutsByWeekday: [String: [Workout]] = [:]
    @Published var completedWorkoutsByDate: [String: [WorkoutResult]] = [:] // 完了したワークアウト履歴
    @Published var workoutNames: [String: String] = [:] // workoutIDをキーとするワークアウト名の辞書
    
    private let calendar: Calendar = .current
    private let workoutService = WorkoutService()
    private let userManager = UserManager.shared
    private let resultService = ResultService() // 追加: ワークアウト結果を取得するサービス
    
    let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    init() {
        self.months = (-2...2).compactMap { calendar.date(byAdding: .month, value: $0, to: selectedDate) }
        self.selectedMonth = selectedDate
        fetchUserRoutine()
        fetchWorkoutHistory() // 初期化時にワークアウト履歴も取得
    }
    
    // ワークアウト名を取得（存在しない場合は適切な代替名を返す）
    func getWorkoutName(for result: WorkoutResult) -> String {
        // すでにキャッシュされている場合はそれを返す
        if let workoutId = result.workoutId, let name = workoutNames[workoutId] {
            return name
        }
        
        // キャッシュされていない場合、ワークアウトIDがあればワークアウト名を非同期で取得
        if let workoutId = result.workoutId {
            Task {
                do {
                    let workout = try await workoutService.fetchWorkoutById(workoutID: workoutId)
                    DispatchQueue.main.async {
                        self.workoutNames[workoutId] = workout.name
                        self.objectWillChange.send() // UIを更新
                    }
                } catch {
                    print("[ERROR] ワークアウト名の取得に失敗: \(error.localizedDescription)")
                }
            }
            
            // ロード中は一時的な名前を表示
            return "ワークアウトを読み込み中..."
        }
        
        // ワークアウトIDがない場合、エクササイズ名から生成
        if let firstExercise = result.exercises?.first {
            return firstExercise.exerciseName + "のワークアウト"
        }
        
        // それ以外は「不明」を返す
        return "Quick Start"
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
    
    // ユーザーのワークアウト履歴を取得
    func fetchWorkoutHistory() {
        guard let uid = userManager.currentUser?.uid else {
            print("[ERROR] ユーザーIDが取得できません")
            return
        }
        
        // 現在表示中の月の最初の日と最後の日を計算
        guard let selectedMonth = selectedMonth else { return }
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return
        }
        
        // 前後1ヶ月を含めた期間で取得（カレンダー表示の都合上）
        let startDate = calendar.date(byAdding: .month, value: -1, to: startOfMonth) ?? startOfMonth
        let endDate = calendar.date(byAdding: .month, value: 1, to: endOfMonth) ?? endOfMonth
        
        Task {
            // ResultServiceを使用して指定期間の運動結果を取得
            guard let results = await resultService.fetchWorkoutResults(
                forUser: uid,
                startDate: startDate,
                endDate: endDate
            ) else {
                return
            }
            
            // 日付別に運動結果を整理
            var workoutsByDate: [String: [WorkoutResult]] = [:]
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            for result in results {
                guard let date = result.createdAt?.dateValue() else { continue }
                let dateString = dateFormatter.string(from: date)
                workoutsByDate[dateString, default: []].append(result)
            }
            
            DispatchQueue.main.async {
                self.completedWorkoutsByDate = workoutsByDate
                print("[DEBUG] 完了したワークアウト履歴を取得しました: \(workoutsByDate.count)日分")
            }
        }
    }
    
    // 指定日に完了したワークアウトを取得
    func getCompletedWorkoutsForDate(_ date: Date) -> [WorkoutResult] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        return completedWorkoutsByDate[dateString] ?? []
    }
    
    // 日付にワークアウト履歴があるかどうか確認
    func hasCompletedWorkout(on date: Date) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        return completedWorkoutsByDate[dateString]?.isEmpty == false
    }
    
    // userが設定したScheduleDaysから、曜日ごとにカテゴライズ
    private func categorizeWorkoutsByWeekday(_ workouts: [Workout]) {
        var categorizedWorkouts: [String: [Workout]] = [:]
        
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
        fetchWorkoutHistory() // 月が変わったらワークアウト履歴も再取得
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
    func getWorkoutsForWeekday(index: Int) -> [Workout] {
        guard index >= 0, index < weekdays.count else { return [] }
        let weekday = weekdays[index]
        return workoutsByWeekday[weekday] ?? []
    }
}
