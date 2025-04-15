//
//  WorkoutService.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/11/08.
//

import Foundation
import Firebase
import FirebaseFirestore

class WorkoutService {
    private let db = Firestore.firestore()

    // ワークアウトを作成(Create)
    func createWorkout(workout: Workout) async -> Result<Void, Error> {
        let workoutDocumentRef = db.collection("Workouts").document()
        
        do {
            try workoutDocumentRef.setData(from: workout)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    /// 기존 워크아웃 도큐먼트의 요일 데이터를 업데이트 (새로운 구조에서는 ScheduledDays는 [String] 타입)
    func updateScheduledDaysForWorkout(workoutID: String, scheduledDays: [String], completion: @escaping (Bool) -> Void) {
        db.collection("Workouts").document(workoutID).updateData([
            "ScheduledDays": scheduledDays
        ]) { error in
            if let error = error {
                print("Error updating scheduled days: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    /// 워크아웃에 운동을 추가하는 메서드 (새로운 운동 구조: name, part, 그리고 빈 Sets 배열)
    func addExerciseToWorkout(workoutID: String, exercise: WorkoutExercise, completion: @escaping (Bool) -> Void) {
        let exerciseData: [String: Any] = [
            "id": exercise.id,         // 고유 ID 저장
            "name": exercise.name,
            "part": exercise.part,
            "Sets": [] // 초기 세트 배열 (빈 배열)
        ]
        
        db.collection("Workouts").document(workoutID).updateData([
            "exercises": FieldValue.arrayUnion([exerciseData])
        ]) { error in
            if let error = error {
                print("🔥 에크서사이즈 추가 에러: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ 에크서사이즈가 정상적으로 추가되었습니다!")
                completion(true)
            }
        }
    }
    
    /// 引数のユーザーが登録済みのワークアウトを全て取得
    func fetchUserWorkouts(uid: String) async -> [Workout]? {
        let db = Firestore.firestore()
        let workoutsRef = db.collection("Workouts").whereField("userId", isEqualTo: uid)

        do {
            let snapshot = try await workoutsRef.getDocuments()
            var workouts: [Workout] = []

            for document in snapshot.documents {
                do {
                    let workout = try document.data(as: Workout.self)
                    workouts.append(workout)
                } catch {
                    print("[ERROR] Workoutのデコードエラー: \(error)")
                }
            }
            return workouts

        } catch {
            print("[ERROR] Firestore 取得エラー: \(error)")
            return nil
        }
    }
}
