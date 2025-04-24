//
//  ExerciseService.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2024/12/09.
//

import Foundation
import FirebaseFirestore
import Firebase

final class ExerciseService {
    private let db = Firestore.firestore()

    // エクササイズのフェッチ、名前と部位で絞り込み可能
    func fetchExercises(name: String? = nil, part: ExercisePart? = nil, limit: Int = 20 ) async -> Result<[Exercise], Error> {
        var query: Query = db.collection("Exercises")
        
        if let name, !name.isEmpty {
            // 前方一致
            query = query.whereField("name", isGreaterThanOrEqualTo: name).whereField("name", isLessThanOrEqualTo: name + "\u{f8ff}")
        }
        
        if let part {
            query = query.whereField("part", isEqualTo: part.rawValue)
        }
        
        query = query.limit(to: limit)
        
        do {
            let snapshot = try await query.getDocuments()
            let exercises = try snapshot.documents.compactMap { doc in
                try doc.data(as: Exercise.self)
            }
            
            return .success(exercises)
        } catch {
            return .failure(error)
        }
    }
    
    // idからエクササイズを取得
    func fetchExerciseById(id: String) async -> Result<Exercise, Error> {
        let docRef = db.collection("Exercises").document(id)
        
        do {
            let exercise = try await docRef.getDocument(as: Exercise.self)
            return .success(exercise)
        } catch {
            return .failure(error)
        }
    }
}
