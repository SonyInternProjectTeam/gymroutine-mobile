//
//  WorkoutViewModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/11/08.
//

import Foundation
import FirebaseAuth

// TODO : ViewとViewModelは１：１関係このViewModel修正要

class CreateWorkoutViewModel: ObservableObject {
    @Published var trainOptions: [String] = []
    @Published var exercises: [String] = []
    private var service = WorkoutService()
    private var currentWorkoutID: String?
    
//    func createWorkout() {
//        guard let userID = Auth.auth().currentUser?.uid else {
//            print("User is not logged in")
//            return
//        }
//        
//        service.createWorkoutDocument(userID: userID) { documentID in
//            if let documentID = documentID {
//                self.currentWorkoutID = documentID
//                self.fetchTrainOptions()
//            }
//        }
//    }
    
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
    
    func addScheduledDaysToWorkout(selectedDays: [String: Bool]) {
        guard let workoutID = currentWorkoutID else { return }
            
        let scheduledDays = selectedDays.filter { $0.value == true } // trueの曜日だけを取得
            
        service.addScheduledDaysToWorkout(workoutID: workoutID, scheduledDays: scheduledDays) { success in
            if success {
                print("Scheduled days added successfully")
            } else {
                print("Failed to add scheduled days")
            }
        }
    }
    
    // ワークアウト名と曜日をまとめてFirestoreに保存
    func createWorkoutWithDetails(name: String, selectedDays: [String: Bool], completion: @escaping (String?) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User is not logged in")
            completion(nil)
            return
        }

        let scheduledDays = selectedDays.filter { $0.value }.keys.sorted() // 선택된 요일만 저장

        // 🟢 Firestore에 워크아웃 도큐먼트 생성 (이름과 요일 포함)
        service.createWorkoutDocument(userID: userID, name: name, scheduledDays: scheduledDays) { documentID in
            if let documentID = documentID {
                DispatchQueue.main.async {
                    print("Workout created successfully with ID: \(documentID)")
                    self.currentWorkoutID = documentID
                    completion(documentID) // 생성된 workout ID를 반환
                }
            } else {
                print("Failed to create workout document")
                completion(nil)
            }
        }
    }

}
