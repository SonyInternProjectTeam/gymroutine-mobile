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
    
    func appendExercise(exercise: Exercise) {
        let newWorkoutExercise = WorkoutExercise(
            name: exercise.name,
            part: exercise.part,
            sets: [ExerciseSet(reps: 0, weight: 0)])
        exercises.append(newWorkoutExercise)
    }
    
    func addExerciseSet(workoutExercise: WorkoutExercise) {
        if let index = exercises.firstIndex(where: { $0.id == workoutExercise.id }) {
            exercises[index].sets.append(ExerciseSet(reps: 0, weight: 0))
        }
    }
}

final class NewCreateWorkoutViewModel: WorkoutExecisesManager {
    @Published var workoutName: String = ""
    @Published var isRoutine = false
    @Published var selectedDays: Set<Weekday> = []
    
    func toggleSelectionWeekDay(for day: Weekday) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
}
