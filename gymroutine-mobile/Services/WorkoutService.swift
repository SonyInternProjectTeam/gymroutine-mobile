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
        // 초기 데이터를 구성
        let workoutData: [String: Any] = [
            "UUid": userID,
            "Name": name,                      // 워크아웃 이름
            "ScheduledDays": scheduledDays,    // 선택된 요일
            "CreatedAt": FieldValue.serverTimestamp() // 생성 시간
        ]
        
        // Firestore에 워크아웃 데이터 추가
        var ref: DocumentReference? = nil
        ref = db.collection("Workouts").addDocument(data: workoutData) { error in
            if let error = error {
                print("Error adding workout document: \(error)")
                completion(nil)
            } else {
                // 성공적으로 생성된 문서 ID 반환
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
        db.collection("Workouts").document(workoutID).collection("exerciseMenus").addDocument(data: [
            "name": exerciseName,
            "part": part,
            "isCompleted": false
        ]) { error in
            if let error = error {
                print("Error adding exercise to workout: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
}

