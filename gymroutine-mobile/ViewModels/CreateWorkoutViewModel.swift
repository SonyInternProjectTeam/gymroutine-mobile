//
//  WorkoutViewModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/11/08.
//

import Foundation
import FirebaseAuth

class CreateWorkoutViewModel: ObservableObject {
    @Published var trainOptions: [String] = []
    @Published var exercises: [String] = []
    private var service = WorkoutService()
    private var currentWorkoutID: String?
    
    func fetchTrainOptions() {
        service.fetchTrainOptions { options in
            DispatchQueue.main.async {
                self.trainOptions = options
            }
        }
    }
    
    func fetchExercises(for train: String) {
        service.fetchExercises(for: train) { exercises in
            DispatchQueue.main.async {
                self.exercises = exercises
            }
        }
    }
    
    func addExerciseToWorkout(workoutID: String, exercise: WorkoutExercise, completion: @escaping (Bool) -> Void) {
        service.addExerciseToWorkout(workoutID: workoutID, exercise: exercise, completion: completion)
    }


    
    // 워크아웃명과 선택된 요일(딕셔너리 -> 배열) 정보를 Firestore에 저장
    func createWorkoutWithDetails(name: String, selectedDays: [String: Bool], completion: @escaping (String?) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User is not logged in")
            completion(nil)
            return
        }

        // 선택된 요일을 배열로 변환
        let scheduledDays = selectedDays.filter { $0.value }.map { $0.key }.sorted()

        service.createWorkoutDocument(userID: userID, name: name, scheduledDays: scheduledDays) { documentID in
            if let documentID = documentID {
                DispatchQueue.main.async {
                    print("Workout created successfully with ID: \(documentID)")
                    self.currentWorkoutID = documentID
                    completion(documentID)
                }
            } else {
                print("Failed to create workout document")
                completion(nil)
            }
        }
    }
}
