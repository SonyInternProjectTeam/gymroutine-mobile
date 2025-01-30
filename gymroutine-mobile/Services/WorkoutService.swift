//
//  WorkoutService.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/11/08.
//

import Foundation
import Firebase

class WorkoutService {
    private let db = Firestore.firestore()

    /// 워크아웃 도큐먼트를 생성하면서 이름과 요일 데이터를 추가
    func createWorkoutDocument(userID: String, name: String, scheduledDays: [String], completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        var ref: DocumentReference? = nil

        let workoutData: [String: Any] = [
            "uuid": userID,      // 사용자 ID
            "name": name,        // 워크아웃 이름
            "ScheduledDays": scheduledDays, // 선택한 요일
            "CreatedAt": Timestamp(date: Date()) // 생성 시간
        ]

        ref = db.collection("Workouts").addDocument(data: workoutData) { error in
            if let error = error {
                print("Error adding workout document: \(error)")
                completion(nil)
            } else {
                completion(ref?.documentID)
            }
        }
    }


    /// 기존 워크아웃 도큐먼트에 요일 데이터만 추가
    func addScheduledDaysToWorkout(workoutID: String, scheduledDays: [String: Bool], completion: @escaping (Bool) -> Void) {
        db.collection("Workouts").document(workoutID).updateData([
            "ScheduledDays": scheduledDays
        ]) { error in
            if let error = error {
                print("Error adding scheduled days: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    /// 기존 워크아웃 도큐먼트에 제목 및 요일 데이터를 추가
    func addWorkoutDetails(workoutID: String, name: String, scheduledDays: [String: Bool], completion: @escaping (Bool) -> Void) {
        db.collection("Workouts").document(workoutID).updateData([
            "name": name,
            "ScheduledDays": scheduledDays
        ]) { error in
            if let error = error {
                print("Error adding workout details: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    /// 운동 옵션을 불러오는 메서드
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

    /// 특정 트레인의 운동 목록을 불러오는 메서드
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

    /// 워크아웃에 운동을 추가하는 메서드
    func addExerciseToWorkout(workoutID: String, exerciseName: String, part: String, completion: @escaping (Bool) -> Void) {
        // 추가할 운동 데이터
            let newExercise = [
                "name": exerciseName,
                "part": part,
                "sets": 0,
                "reps":0,
                "weight" :0,
                "isCompleted": false
            ] as [String : Any]
            
            // Workouts 문서에 "exercises" 필드를 배열로 추가 또는 업데이트
            db.collection("Workouts").document(workoutID).updateData([
                "exercises": FieldValue.arrayUnion([newExercise]) // 운동 배열에 추가
            ]) { error in
                if let error = error {
                    print("Error adding exercise to workout: \(error)")
                    completion(false) // 실패 처리
                } else {
                    print("✅ Successfully added exercise directly to workout: \(exerciseName)")
                    completion(true) // 성공 처리
            }
        }
    }
    
    func fetchWorkoutDetails(workoutID: String, completion: @escaping (Result<Workout, Error>) -> Void) {
        let db = Firestore.firestore()
        db.collection("Workouts").document(workoutID).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
            } else if let document = document, document.exists {
                let data = document.data() ?? [:]
                let workout = Workout(
                    id: workoutID,
                    name: data["name"] as? String ?? "Unknown",
                    scheduledDays: data["ScheduledDays"] as? [String] ?? [],
                    createdAt: (data["CreatedAt"] as? Timestamp)?.dateValue() ?? Date()
                )
                completion(.success(workout))
            } else {
                completion(.failure(NSError(domain: "Firestore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Workout not found"])))
            }
        }
    }

}

