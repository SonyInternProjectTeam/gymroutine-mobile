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
    
    /// 워크아웃의 exercises 필드를 업데이트하는 메서드
    func updateWorkoutExercises(workoutID: String, exercises: [WorkoutExercise]) async -> Result<Void, Error> {
        do {
            // Convert WorkoutExercise objects to Firestore-compatible dictionaries
            let exercisesData = exercises.map { exercise -> [String: Any] in
                var exerciseDict: [String: Any] = [
                    "id": exercise.id,
                    "name": exercise.name,
                    "part": exercise.part
                ]
                
                // Convert sets to array of dictionaries
                let setsArray = exercise.sets.map { set -> [String: Any] in
                    return [
                        "reps": set.reps,
                        "weight": set.weight
                    ]
                }
                
                exerciseDict["sets"] = setsArray
                return exerciseDict
            }
            
            try await db.collection("Workouts").document(workoutID).updateData([
                "exercises": exercisesData
            ])
            return .success(())
        } catch {
            print("🔥 워크아웃 exercises 업데이트 에러: \(error.localizedDescription)")
            return .failure(error)
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
    
    /// 워크아웃 상세 정보를 불러오는 메서드 (exercises 필드도 디코딩)
    func fetchWorkoutById(workoutID: String) async throws -> Workout {
        let documentSnapshot = try await db.collection("Workouts").document(workoutID).getDocument()
        
        guard documentSnapshot.exists else {
            throw NSError(domain: "Firestore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Workout not found"])
        }
        
        // Firestore 문서를 Workout 모델로 변환
        do {
            var workout = try documentSnapshot.data(as: Workout.self)
            workout.id = documentSnapshot.documentID
            return workout
        } catch {
            print("🔥 워크아웃 디코딩 에러: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 운동 옵션(Trains 컬렉션) 불러오기
    func fetchTrainOptions(completion: @escaping ([String]) -> Void) {
        db.collection("Trains").getDocuments { (snapshot, error) in
            guard let documents = snapshot?.documents, error == nil else {
                print("Error fetching train options: \(String(describing: error))")
                completion([])
                return
            }
            let options = documents.map { $0.documentID }
            completion(options)
        }
    }
    
    /// 특정 트레인의 운동 목록 불러오기
    func fetchExercises(for train: String, completion: @escaping ([String]) -> Void) {
        db.collection("Trains").document(train).collection("exercises").getDocuments { (snapshot, error) in
            guard let documents = snapshot?.documents, error == nil else {
                print("Error fetching exercises: \(String(describing: error))")
                completion([])
                return
            }
            let exercises = documents.map { $0.documentID }
            completion(exercises)
        }
    }
}
