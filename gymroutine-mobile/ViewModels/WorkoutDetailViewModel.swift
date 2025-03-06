//
//  Workout DetailViewModel.swift
//  gymroutine-mobile
//
//  Created by sony on 2025/01/05.
//

import Foundation
import FirebaseFirestore

class WorkoutDetailViewModel: ObservableObject {
    @Published var workout: Workout?
    @Published var exercises: [WorkoutExercise] = [] // ✅ WorkoutExercise の型を維持
    
    private let db = Firestore.firestore()
    
    // ✅ ワークアウトの詳細情報を取得
    func fetchWorkoutDetails(workoutID: String) {
        let docRef = db.collection("Workouts").document(workoutID)
        docRef.getDocument { snapshot, error in
            guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data(), error == nil else {
                print("🔥 ワークアウトの取得エラー: \(error?.localizedDescription ?? "不明なエラー")")
                return
            }
            
            DispatchQueue.main.async {
                self.workout = Workout(
                    id: snapshot.documentID,
                    name: data["name"] as? String ?? "Unknown",
                    scheduledDays: data["ScheduledDays"] as? [String] ?? [],
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                )
            }
            
            // ✅ エクササイズのリストも取得
            self.fetchExercises(for: workoutID)
        }
    }
    
    // ✅ エクササイズのリストを取得
    func fetchExercises(for workoutID: String) {
        let docRef = db.collection("Workouts").document(workoutID)
        docRef.getDocument { snapshot, error in
            guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data(), error == nil else {
                print("🔥 エクササイズの取得エラー: \(error?.localizedDescription ?? "不明なエラー")")
                return
            }
            
            if let exerciseList = data["exercises"] as? [[String: Any]] {
                let exercises = exerciseList.compactMap { exerciseData -> WorkoutExercise? in
                    guard let name = exerciseData["name"] as? String,
                          let part = exerciseData["part"] as? String,
                          let sets = exerciseData["sets"] as? Int,
                          let reps = exerciseData["reps"] as? Int,
                          let weight = exerciseData["weight"] as? Int
                    else { return nil }
                    
                    return WorkoutExercise(
                        name: name,
                        description: "", // Firestoreに description がない
                        img: "", // Firestoreに img がない
                        part: part,
                        sets: sets,
                        reps: reps,
                        weight: weight
                    )
                }
                
                DispatchQueue.main.async {
                    self.exercises = exercises
                }
            }
        }
    }
    
    // ✅ エクササイズを追加
    func addExerciseToWorkout(workoutID: String, exercise: WorkoutExercise) {
        let exerciseData: [String: Any] = [
            "name": exercise.name,
            "part": exercise.part,
            "isCompleted": false,
            "sets": 0,
            "reps": 0,
            "weight": 0
        ]
        
        db.collection("Workouts").document(workoutID).updateData([
            "exercises": FieldValue.arrayUnion([exerciseData])
        ]) { error in
            if let error = error {
                print("🔥 エクササイズの追加エラー: \(error.localizedDescription)")
            } else {
                print("✅ エクササイズが正常に追加されました！")
                DispatchQueue.main.async {
                    self.fetchExercises(for: workoutID) // ✅ エクササイズを追加後にリストを更新
                }
            }
        }
    }
    
    // ✅ エクササイズを更新 (sets, reps, weight の変更)
    func updateExercise(workoutID: String, updatedExercise: WorkoutExercise) {
        let docRef = db.collection("Workouts").document(workoutID)
        
        docRef.getDocument { snapshot, error in
            guard let snapshot = snapshot, snapshot.exists, var exercises = snapshot.data()?["exercises"] as? [[String: Any]], error == nil else {
                print("🔥 ワークアウトの取得エラー (更新用): \(error?.localizedDescription ?? "不明なエラー")")
                return
            }
            
            if let index = exercises.firstIndex(where: { $0["name"] as? String == updatedExercise.name }) {
                // ✅ 既存のエクササイズを更新
                exercises[index]["sets"] = updatedExercise.sets
                exercises[index]["reps"] = updatedExercise.reps
                exercises[index]["weight"] = updatedExercise.weight
                
                // ✅ Firestoreに更新
                docRef.updateData(["exercises": exercises]) { error in
                    if let error = error {
                        print("🔥 エクササイズの更新エラー: \(error.localizedDescription)")
                    } else {
                        print("✅ エクササイズが正常に更新されました: \(updatedExercise.name)")
                        DispatchQueue.main.async {
                            self.fetchExercises(for: workoutID) // ✅ 更新後、即時反映
                        }
                    }
                }
            }
        }
    }
}
