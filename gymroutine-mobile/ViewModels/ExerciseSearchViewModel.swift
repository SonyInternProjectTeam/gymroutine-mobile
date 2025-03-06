//
//  ExerciseSearchViewModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/01/31.
//

import Foundation
import FirebaseAuth

class ExerciseSearchViewModel: ObservableObject {
    @Published var trainOptions: [String] = []
    @Published var allExercises: [Exercise] = []
    @Published var filterExercises: [Exercise] = []
    @Published var searchWord: String = ""
    @Published var selectedExerciseParts: [ExercisePart] = []
    @Published var selectedExercisePart: ExercisePart? = nil
    private var service = ExerciseService()
    private let workoutService = WorkoutService()

    init() {
        fetchAll()
    }
    func fetchAll() {
        service.fetchTrainParts { options in
            DispatchQueue.main.async {
                self.trainOptions = options
                self.fetchAllExercises(options:self.trainOptions)
            }
        }
    }
    
    func fetchAllExercises(options:[String]) {
        service.fetchAllExercises(for: options) { exercises in
            DispatchQueue.main.async {
                self.allExercises = exercises
                self.filterExercises = self.allExercises
            }
        }
    }
    
    func searchExerciseName(for name: String) {
        var filteredExercises: [Exercise] = []
        allExercises.forEach { exercise in
            if exercise.name.contains(name) {
                filteredExercises.append(exercise)
            }
            if name == "" {
                filteredExercises = allExercises
            }
        }
        filterExercises = filteredExercises
    }
    
    func searchExercisePart() {
        var filteredExercises: [Exercise] = []
        if selectedExercisePart == nil {
            filteredExercises = allExercises
        } else {
            allExercises.forEach { exercise in
                if exercise.part.contains(selectedExercisePart!.rawValue) {
                    filteredExercises.append(exercise)
                }
            }
        }
        filterExercises = filteredExercises
    }
    
    func toggleExercisePart(part: ExercisePart) {
        if let index =  selectedExerciseParts.firstIndex(of: part) {
            selectedExerciseParts.remove(at: index)
        } else {
            selectedExerciseParts.append(part)
        }
    }
    
    func onTapExercisePartToggle(part: ExercisePart){
        toggleExercisePart(part: part)
        searchExercisePart()
    }

    func onTapExercisePlusButton(workoutID: String, exercise: Exercise) {
        addExerciseToWorkout(
            workoutID: workoutID,
            exerciseName: exercise.name,
            part: exercise.part
        ) { success in
            // TODO: 画面遷移
            if success {
                print("운동 추가 성공 ✅")
            } else {
                print("운동 추가 실패 ❌")
            }
        }
    }

    func addExerciseToWorkout(workoutID: String, exerciseName: String, part: String, completion: @escaping (Bool) -> Void) {
        workoutService.addExerciseToWorkout(workoutID: workoutID, exerciseName: exerciseName, part: part) { success in
            DispatchQueue.main.async {
                completion(success) // UI 업데이트를 위해 메인 스레드에서 실행
            }
        }
    }
}
