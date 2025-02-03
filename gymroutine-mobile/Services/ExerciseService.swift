//
//  ExerciseService.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2024/12/09.
//

import Foundation
import FirebaseFirestore
import Firebase

class ExerciseService {
    func fetchAllExercises(for options: [String], completion: @escaping ([Exercise]) -> Void) {
        let db = Firestore.firestore()
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

    
    func fetchTrainParts(completion: @escaping ([String]) -> Void) {
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
}
