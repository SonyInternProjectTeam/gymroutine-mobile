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
class WorkoutExercisesManager: ObservableObject {
    @Published var exercises: [WorkoutExercise] = []
    
    //ExerciseをWorkoutExerciseに変換しながら追加
    func appendExercise(exercise: Exercise) {
        let newWorkoutExercise = WorkoutExercise(
            name: exercise.name,
            part: exercise.part,
            sets: [ExerciseSet(reps: 0, weight: 0)])
        exercises.append(newWorkoutExercise)
        UIApplication.showBanner(type: .success, message: "\(LocalizedStringKey(exercise.name))を追加しました")
    }
    
    func removeExercise(_ workoutExercise: WorkoutExercise) {
        exercises.removeAll { $0.id == workoutExercise.id }
        UIApplication.showBanner(type: .notice, message: "\(LocalizedStringKey(workoutExercise.name))を削除しました")
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
    @Published var isRoutine = false
    @Published var selectedDays: Set<Weekday> = []
    @Published var selectedIndex: Int? = nil
    //ModalFlg
    @Published var searchExercisesFlg = false
    @Published var editExerciseSetsFlg = false
    
    private let service = WorkoutService()
    
    func toggleSelectionWeekDay(for day: Weekday) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
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
            fatalError("[ERROR] ログインしていません")
        }
        
        guard !self.workoutName.isEmpty else {
            UIApplication.showBanner(type: .error, message: "ワークアウト名を入力してください")
            return
        }
        
        // 週の順番にソート処理
        let sortedDays = selectedDays.sorted { lhs, rhs in
            Weekday.allCases.firstIndex(of: lhs)! < Weekday.allCases.firstIndex(of: rhs)!
        }

        let workout = Workout(
            userId: userId,
            name: self.workoutName,
            createdAt: Date(),
            notes: self.notes.isEmpty ? nil : self.notes,
            isRoutine: self.isRoutine,
            scheduledDays: sortedDays.map { $0.rawValue },
            exercises: self.exercises
        )
        Task {
            UIApplication.showLoading()
            let result = await service.createWorkout(workout: workout)
            switch result {
            case .success(_):
                print("[DEBUG] ワークアウトの作成に成功しました！")
                completion()    //View側にモーダル閉じを指示
            case .failure(let error):
                print(error.localizedDescription)
            }
            UIApplication.hideLoading()
        }
    }
}
