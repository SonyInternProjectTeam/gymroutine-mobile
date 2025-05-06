//
//  ExerciseModel.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2024/12/13.
//

import Foundation
import FirebaseFirestore

struct Exercise: Codable, Hashable {
    @DocumentID var id: String?
    let key: String
    let name: String
    let description: String
    let part: String
    let detailedPart: String
    
    func toExercisePart() -> ExercisePart? {
        return ExercisePart(rawValue: part)
    }

    static func mock() -> Exercise{
        return Exercise(
            key: "sample",
            name: "サンプルエクササイズ",
            description: "サンプルの部位を鍛えることができます",
            part: ExercisePart.arms.rawValue,
            detailedPart: "test"
        )
    }
}

enum ExercisePart: String, CaseIterable {
    case arms
    case abscore = "abs/core"
    case chest
    case back
    case lowerbody = "lower body"
    case shoulders
}

// 今後detailedPart検索機能実装の際に使用
//enum ExerciseDetailedPart: String, CaseIterable {
//    // Lower body
//    case quadriceps
//    case adductors
//    case hamstrings
//    case glutes
//    case calves
//    // Chest
//    case upperChest
//    case midChest
//    case lowerChest
//    // Back
//    case lats
//    case midBack
//    case traps
//    case lowerBack
//    // Shoulders
//    case anteriorDeltoid
//    case lateralDeltoid
//    case posteriorDeltoid
//    // Arms
//    case biceps
//    case triceps
//    case forearms
//    // Abs
//    case rectusAbdominis
//    case obliques
//    case deepCore
//}

// 새롭게 추가: 각 세트의 정보를 관리하는 모델
struct ExerciseSet: Identifiable, Codable {
    var id: String = UUID().uuidString
    var reps: Int
    var weight: Double
    
    //Firestore書き込み時にidを無視
    private enum CodingKeys: String, CodingKey {
        case reps, weight
    }
}

// 기존 WorkoutExercise 모델을 수정하여 세트 정보를 배열로 관리하도록 변경
struct WorkoutExercise: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String           // 운동 이름 (예: "benchpress")
    var part: String           // 운동 부위 (예: "chest")
    var key: String            // 画像呼び出しのために定義
    var sets: [ExerciseSet]    // 각 세트의 정보 (예: [{ reps: 12, weight: 50 }, ...])
    var restTime: Int?         // 휴식 시간 (초 단위), nil일 경우 기본값(90초) 사용
    
    private enum CodingKeys: String, CodingKey {
        case id, name, part, key, sets, restTime
    }
    
    static func mock() -> WorkoutExercise {
        return WorkoutExercise(
            name: "Bench Press",
            part: "chest",
            key: "Bench Press",
            sets: [
                ExerciseSet(reps: 12, weight: 50.0),
                ExerciseSet(reps: 10, weight: 55.0),
                ExerciseSet(reps: 8, weight: 60.0),
            ],
            restTime: 90
        )
    }
}
