//
//  WorkoutViewModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/11/08.
//

import Foundation
import FirebaseAuth

class WorkoutViewModel: ObservableObject {
    @Published var trainOptions: [String] = []
    @Published var exercises: [String] = []
    private var service = WorkoutService()
    private var currentWorkoutID: String?
    
    func createWorkout() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User is not logged in")
            return
        }
        
        service.createWorkoutDocument(userID: userID) { documentID in
            if let documentID = documentID {
                self.currentWorkoutID = documentID
                self.fetchTrainOptions()
            }
        }
    }
    
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
    
    func addExerciseToWorkout(exerciseName: String, part: String) {
        guard let workoutID = currentWorkoutID else { return }
        
        service.addExerciseToWorkout(workoutID: workoutID, exerciseName: exerciseName, part: part) { success in
            if success {
                print("Exercise added to workout")
            } else {
                print("Failed to add exercise to workout")
            }
        }
    }
}
