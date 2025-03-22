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
    
    
    /// 워크아웃 상세 정보를 불러오는 메서드 (exercises 필드도 디코딩)
    //    func fetchWorkoutDetails(workoutID: String, completion: @escaping (Result<Workout, Error>) -> Void) {
    //        db.collection("Workouts").document(workoutID).getDocument { document, error in
    //            if let error = error {
    //                completion(.failure(error))
    //            } else if let document = document, document.exists {
    //                let data = document.data() ?? [:]
    //                // exercises 필드를 디코딩 시도
    //                var exercises: [WorkoutExercise] = []
    //                if let exercisesData = data["exercises"] as? [[String: Any]] {
    //                    do {
    //                        let jsonData = try JSONSerialization.data(withJSONObject: exercisesData)
    //                        exercises = try JSONDecoder().decode([WorkoutExercise].self, from: jsonData)
    //                    } catch {
    //                        print("Error decoding exercises: \(error)")
    //                    }
    //                }
    //                let workout = Workout(
    //                    id: workoutID,
    //                    userId: data["userId"] as? String ?? "",
    //                    name: data["name"] as? String ?? "Unknown",
    //                    isRoutine: data["isRoutine"] as? Bool ?? false,
    //                    scheduledDays: data["ScheduledDays"] as? [String] ?? [],
    //                    exercises: exercises,
    //                    createdAt: (data["CreatedAt"] as? Timestamp)?.dateValue() ?? Date(),
    //                    notes: data["notes"] as? String ?? ""
    //                )
    //                completion(.success(workout))
    //            } else {
    //                completion(.failure(NSError(domain: "Firestore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Workout not found"])))
    //            }
    //        }
    //    }
    
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
