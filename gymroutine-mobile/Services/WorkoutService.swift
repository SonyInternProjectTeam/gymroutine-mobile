//
//  WorkoutService.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/11/08.
//

import Foundation
import Firebase

class WorkoutService {
    func createWorkoutDocument(userID: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        var ref: DocumentReference? = nil
        ref = db.collection("Workouts").addDocument(data: ["uuid": userID]) { error in
            if let error = error {
                print("Error adding workout document: \(error)")
                completion(nil)
            } else {
                completion(ref?.documentID)
            }
        }
    }
    
    func fetchTrainOptions(completion: @escaping ([String]) -> Void) {
        let db = Firestore.firestore()
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
    
    func fetchExercises(for train: String, completion: @escaping ([String]) -> Void) {
        let db = Firestore.firestore()
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
    
    func addExerciseToWorkout(workoutID: String, exerciseName: String, part: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
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

