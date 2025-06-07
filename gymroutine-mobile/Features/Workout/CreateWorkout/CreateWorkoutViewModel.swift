//
//  NewCreateWorkoutViewModel.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2025/03/15
//  
//

import Foundation
import FirebaseAuth
import SwiftUI

enum Weekday: String, CaseIterable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"

    /// 日本語の表示名
    var japanese: String {
        switch self {
        case .monday: return "月曜日"
        case .tuesday: return "火曜日"
        case .wednesday: return "水曜日"
        case .thursday: return "木曜日"
        case .friday: return "金曜日"
        case .saturday: return "土曜日"
        case .sunday: return "日曜日"
        }
    }
}

// エクササイズのCRUDを管理
@MainActor
class WorkoutExercisesManager: ObservableObject {
    @Published var exercises: [WorkoutExercise] = []
    
    //ExerciseをWorkoutExerciseに変換しながら追加
    func appendExercise(exercise: Exercise) {
        let newWorkoutExercise = WorkoutExercise(
            name: exercise.name,
            part: exercise.part,
            key: exercise.key,
            sets: [ExerciseSet(reps: 0, weight: 0)])
        exercises.append(newWorkoutExercise)
        UIApplication.showBanner(type: .success, message: "\(exercise.name)を追加しました。")
    }
    
    func removeExercise(_ workoutExercise: WorkoutExercise) {
        exercises.removeAll { $0.id == workoutExercise.id }
        UIApplication.showBanner(type: .notice, message: "\(workoutExercise.name)を削除しました。")
    }
    
    func updateExerciseSet(for workoutExercise: WorkoutExercise) {
        if let index = exercises.firstIndex(where: { $0.id == workoutExercise.id }) {
            exercises[index].sets = workoutExercise.sets
        }
    }
}

@MainActor
final class CreateWorkoutViewModel: WorkoutExercisesManager {
    @Published var workoutName: String = ""
    @Published var notes: String = ""
    
    // 새로운 스케줄링 시스템
    @Published var scheduleType: WorkoutScheduleType = .oneTime
    @Published var selectedDays: Set<Weekday> = []
    @Published var intervalDays: Int = 1
    @Published var startDate: Date = Date()
    @Published var specificDates: [Date] = []
    
    // 기간 설정
    @Published var hasDuration: Bool = false
    @Published var durationTotalSessions: Int = 10
    @Published var durationWeeks: Int = 4
    @Published var durationEndDate: Date = Calendar.current.date(byAdding: .weekOfYear, value: 4, to: Date()) ?? Date()
    @Published var durationType: DurationType = .sessions
    
    // 기존 호환성
    @Published var isRoutine = false
    
    @Published var selectedIndex: Int? = nil
    //ModalFlg
    @Published var searchExercisesFlg = false
    @Published var editExerciseSetsFlg = false
    
    private let service = WorkoutService()
    
    enum DurationType: String, CaseIterable {
        case sessions = "sessions"
        case weeks = "weeks"
        case endDate = "endDate"
        
        var displayName: String {
            switch self {
            case .sessions: return "総回数"
            case .weeks: return "週単位"
            case .endDate: return "終了日"
            }
        }
    }
    
    // 날짜 포매터
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    func toggleSelectionWeekDay(for day: Weekday) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
    
    func addSpecificDate() {
        specificDates.append(Date())
    }
    
    func removeSpecificDate(at index: Int) {
        specificDates.remove(at: index)
    }
    
    func onClickedExerciseSets(index: Int) {
        selectedIndex = index
        editExerciseSetsFlg = true
    }
    
    func onClickedAddExerciseButton() {
        searchExercisesFlg = true
    }
    
    // ワークアウト作成
    func onClickedCreateWorkoutButton(completion: @escaping () -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            fatalError("[ERROR] 로그인되어 있지 않습니다")
        }
        
        guard !self.workoutName.isEmpty else {
            UIApplication.showBanner(type: .error, message: "ワークアウト名を入力してください")
            return
        }
        
        // 스케줄 유효성 검사
        if !validateSchedule() {
            return
        }
        
        // 스케줄 설정 생성
        let schedule = createWorkoutSchedule()
        
        // 기간 설정 생성
        let duration = hasDuration ? createWorkoutDuration() : nil
        
        let workout = Workout(
            userId: userId,
            name: self.workoutName,
            createdAt: Date(),
            notes: self.notes.isEmpty ? nil : self.notes,
            schedule: schedule,
            duration: duration,
            exercises: self.exercises
        )
        
        Task {
            UIApplication.showLoading()
            let result = await service.createWorkout(workout: workout)
            switch result {
            case .success(_):
                print("[DEBUG] ワークアウトが作成されました！")
                completion()    //View側にモーダル閉じを指示
            case .failure(let error):
                print(error.localizedDescription)
            }
            UIApplication.hideLoading()
        }
    }
    
    private func validateSchedule() -> Bool {
        switch scheduleType {
        case .oneTime:
            return true
        case .weekly:
            if selectedDays.isEmpty {
                UIApplication.showBanner(type: .error, message: "曜日を選択してください")
                return false
            }
            return true
        case .interval:
            if intervalDays < 1 {
                UIApplication.showBanner(type: .error, message: "間隔は1日以上である必要があります")
                return false
            }
            return true
        case .specificDates:
            if specificDates.isEmpty {
                UIApplication.showBanner(type: .error, message: "日付を追加してください")
                return false
            }
            return true
        }
    }
    
    private func createWorkoutSchedule() -> WorkoutSchedule {
        switch scheduleType {
        case .oneTime:
            return WorkoutSchedule(
                type: .oneTime,
                weeklyDays: nil,
                intervalDays: nil,
                startDate: startDate,
                specificDates: nil
            )
        case .weekly:
            let sortedDays = selectedDays.sorted { lhs, rhs in
                Weekday.allCases.firstIndex(of: lhs)! < Weekday.allCases.firstIndex(of: rhs)!
            }
            return WorkoutSchedule(
                type: .weekly,
                weeklyDays: sortedDays.map { $0.rawValue },
                intervalDays: nil,
                startDate: startDate,
                specificDates: nil
            )
        case .interval:
            return WorkoutSchedule(
                type: .interval,
                weeklyDays: nil,
                intervalDays: intervalDays,
                startDate: startDate,
                specificDates: nil
            )
        case .specificDates:
            return WorkoutSchedule(
                type: .specificDates,
                weeklyDays: nil,
                intervalDays: nil,
                startDate: nil,
                specificDates: specificDates.sorted()
            )
        }
    }
    
    private func createWorkoutDuration() -> WorkoutDuration {
        switch durationType {
        case .sessions:
            return WorkoutDuration(
                totalSessions: durationTotalSessions,
                weeks: nil,
                endDate: nil
            )
        case .weeks:
            return WorkoutDuration(
                totalSessions: nil,
                weeks: durationWeeks,
                endDate: Calendar.current.date(byAdding: .weekOfYear, value: durationWeeks, to: startDate)
            )
        case .endDate:
            return WorkoutDuration(
                totalSessions: nil,
                weeks: nil,
                endDate: durationEndDate
            )
        }
    }
}
