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
    
    func fetchAllExercises(for options: [String], completion: @escaping ([Exercise]) -> Void) {
        var exercises: [Exercise] = []
        let group = DispatchGroup() // ✅ 여러 Firestore 요청을 동기적으로 관리

        for option in options {
            group.enter() // ✅ Firestore 요청 시작
            db.collection("Trains").document(option).collection("exercises").getDocuments { snapshot, error in
                if let error = error {
                    print("Error getting documents: \(error.localizedDescription)")
                    group.leave() // 요청 종료
                    return
                }
                snapshot?.documents.forEach { document in
                    do {
                        let exercise = try document.data(as: Exercise.self)
                        exercises.append(exercise)
                    } catch {
                        print("Error decoding document: \(error.localizedDescription)")
                    }
                }
                group.leave() // ✅ Firestore 요청 종료
            }
        }
        
        // ✅ 모든 Firestore 요청이 끝나면 실행
        group.notify(queue: .main) {
            completion(exercises)
        }
    }
    
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
}
