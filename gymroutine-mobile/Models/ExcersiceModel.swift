//
//  ExerciseModel.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2024/12/13.
//

import Foundation

struct Exercise: Codable, Hashable {
    var name: String = ""
    var description: String = ""
    var img: String = ""
    var part: String = ""
    
    func toExercisePart() -> ExercisePart? {
        return ExercisePart(rawValue: part)
    }

    static func mock() -> Exercise{
        return Exercise(
            name: "サンプルエクササイズ",
            description: "サンプルの部位を鍛えることができます",
            img: "https://picsum.photos/200",
            part: ExercisePart.arm.rawValue
        )
    }
}

enum ExercisePart: String, CaseIterable {
    case arm
    case chest
    case back
    case legs
}

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
    var sets: [ExerciseSet]    // 각 세트의 정보 (예: [{ reps: 12, weight: 50 }, ...])
    var restTime: Int?         // 휴식 시간 (초 단위), nil일 경우 기본값(90초) 사용
    
    private enum CodingKeys: String, CodingKey {
        case id, name, part, sets, restTime
    }
    
    static func mock() -> WorkoutExercise {
        return WorkoutExercise(
            name: "Bench Press",
            part: "chest",
            sets: [
                ExerciseSet(reps: 12, weight: 50.0),
                ExerciseSet(reps: 10, weight: 55.0),
                ExerciseSet(reps: 8, weight: 60.0)
            ],
            restTime: 90
        )
    }
}
