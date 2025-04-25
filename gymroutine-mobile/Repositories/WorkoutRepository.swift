//
//  WorkoutRepository.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/03/22.
//

import Foundation
import FirebaseFirestore

class WorkoutRepository {
    private let db = Firestore.firestore()
    
    /// 특정 사용자의 워크아웃 목록을 불러옵니다.
    func fetchWorkouts(for userID: String) async throws -> [Workout] {
        print("DEBUG: Fetching workouts for userID: \(userID)")
        let snapshot = try await db.collection("Workouts")
            .whereField("userId", isEqualTo: userID)
            .getDocuments()
        print("DEBUG: Fetched \(snapshot.documents.count) documents from Firestore")
        
        return try snapshot.documents.compactMap { document in
            do {
                let workout = try document.data(as: Workout.self)
                print("DEBUG: Successfully decoded workout: \(workout.name)")
                return workout
            } catch {
                print("DEBUG: Failed to decode workout with documentID \(document.documentID): \(error)")
                return nil
            }
        }
    }
}
