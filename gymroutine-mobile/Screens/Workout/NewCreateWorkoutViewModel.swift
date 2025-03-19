//
//  NewCreateWorkoutViewModel.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2025/03/15
//  
//

import Foundation

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
class WorkoutExecisesManager: ObservableObject {
    @Published var exercises: [WorkoutExercise] = []
    
    //ExerciseをWorkoutExerciseに変換しながら削除
    func appendExercise(exercise: Exercise) {
        let newWorkoutExercise = WorkoutExercise(
            name: exercise.name,
            part: exercise.part,
            sets: [ExerciseSet(reps: 0, weight: 0)])
        exercises.append(newWorkoutExercise)
    }
    
    func removeExercise(_ workoutExercise: WorkoutExercise) {
        exercises.removeAll { $0.id == workoutExercise.id }
    }
    
    func updateExerciseSet(for workoutExercise: WorkoutExercise) {
        if let index = exercises.firstIndex(where: { $0.id == workoutExercise.id }) {
            exercises[index].sets = workoutExercise.sets
        }
    }
}

final class NewCreateWorkoutViewModel: WorkoutExecisesManager {
    @Published var workoutName: String = ""
    @Published var notes: String = ""
    @Published var isRoutine = false
    @Published var selectedDays: Set<Weekday> = []
    @Published var selectedIndex: Int? = nil
    //ModalFlg
    @Published var searchExercisesFlg = false
    @Published var editExerciseSetsFlg = false
    
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
}
