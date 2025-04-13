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
@MainActor
final class ExerciseSearchViewModel: ObservableObject {
    @Published var recommendedExercises: [Exercise] = []
    @Published var filterExercises: [Exercise] = []
    @Published var searchWord: String = ""
    @Published var selectedExerciseParts: [ExercisePart] = []
    @Published var selectedExercisePart: ExercisePart? = nil
    private var service = ExerciseService()
    private let workoutService = WorkoutService()
    
    private let recommendExeciseIds: [String] = ["qO1BfPHJXlHcoRhzh24n","qX8qffKedwHds0qMI44H"]
    
    
    @Published var isBoolmarkOnly: Bool = false

    init() {
        fetchAll()
    }
    
    func fetchAll() {
        service.fetchTrainParts { options in
            DispatchQueue.main.async {
                self.trainOptions = options
                self.fetchAllExercises(options: self.trainOptions)
            }
        }
        fetchRecommendExercise()
    }
    
    func fetchAllExercises(options: [String]) {
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
    //事前に指定したエクササイズをおすすめとして取得
    func fetchRecommendExercise() {
        Task {
            isLoading = true
            var fetchedExercises: [Exercise] = []
            
            await withTaskGroup(of: Result<Exercise, Error>.self) { group in
                for id in recommendExeciseIds {
                    group.addTask {
                        return await self.service.fetchExerciseById(id: id)
                    }
                }

                for await result in group {
                    switch result {
                    case .success(let exercise):
                        fetchedExercises.append(exercise)
                    case .failure(let error):
                        print("[ERROR] おすすめエクササイズ取得失敗: \(error.localizedDescription)")
                    }
                }
            }

            self.recommendedExercises = fetchedExercises
            isLoading = false
        }
    }
    
    func toggleExercisePart(part: ExercisePart) {
        if let index = selectedExerciseParts.firstIndex(of: part) {
            selectedExerciseParts.remove(at: index)
        } else {
            selectedExerciseParts.append(part)
        }
    }
    
    func onTapExercisePartToggle(part: ExercisePart) {
        toggleExercisePart(part: part)
        searchExercisePart()
    }
    
    // 수정된 onTapExercisePlusButton: Exercise 객체를 받아 WorkoutExercise를 생성하여 추가합니다.
    func onTapExercisePlusButton(workoutID: String, exercise: Exercise) {
        let newWorkoutExercise = WorkoutExercise(
            id: UUID().uuidString,
            name: exercise.name,
            part: exercise.part,
            sets: [] // 초기 세트 배열은 빈 배열
        )
        addExerciseToWorkout(workoutID: workoutID, exercise: newWorkoutExercise) { success in
            if success {
                print("운동 추가 성공 ✅")
            } else {
                print("운동 추가 실패 ❌")
            }
        }
    }
    
    // 수정된 addExerciseToWorkout: WorkoutExercise 객체를 전달합니다.
    func addExerciseToWorkout(workoutID: String, exercise: WorkoutExercise, completion: @escaping (Bool) -> Void) {
        workoutService.addExerciseToWorkout(workoutID: workoutID, exercise: exercise, completion: completion)
    }
}
