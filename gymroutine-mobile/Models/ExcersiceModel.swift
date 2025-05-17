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
    
    // 画像表示用に定義
    var assetName: String {
            return self.rawValue.replacingOccurrences(of: "/", with: ":")
        }
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
    
    // Firestore에서 데이터를 디코딩하기 위한 커스텀 디코더
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // reps는 Int나 String 형태일 수 있음
        if let repsInt = try? container.decode(Int.self, forKey: .reps) {
            reps = repsInt
        } else if let repsString = try? container.decode(String.self, forKey: .reps),
                  let repsInt = Int(repsString) {
            reps = repsInt
        } else {
            reps = 0 // 기본값
        }
        
        // weight는 Double, Int, 또는 String 형태일 수 있음
        if let weightDouble = try? container.decode(Double.self, forKey: .weight) {
            weight = weightDouble
        } else if let weightInt = try? container.decode(Int.self, forKey: .weight) {
            weight = Double(weightInt)
        } else if let weightString = try? container.decode(String.self, forKey: .weight),
                  let weightDouble = Double(weightString) {
            weight = weightDouble
        } else {
            weight = 0.0 // 기본값
        }
        
        // ID는 생성
        id = UUID().uuidString
    }
    
    // 기존 이니셜라이저 유지
    init(id: String = UUID().uuidString, reps: Int, weight: Double) {
        self.id = id
        self.reps = reps
        self.weight = weight
    }
}

// 기존 WorkoutExercise 모델을 수정하여 세트 정보를 배열로 관리하도록 변경
struct WorkoutExercise: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String           // 운동 이름 (예: "benchpress")
    var part: String           // 운동 부위 (예: "chest")
    var key: String?           // 画像呼び出しのために定義 - optional로 변경
    var sets: [ExerciseSet]    // 각 세트의 정보 (예: [{ reps: 12, weight: 50 }, ...])
    var restTime: Int?         // 휴식 시간 (초 단위), nil일 경우 기본값(90초) 사용
    
    private enum CodingKeys: String, CodingKey {
        case id, name, part, key, sets, restTime
    }
    
    // Firebase에서 데이터를 디코딩하기 위한 커스텀 디코더
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // id는 없을 수 있으므로 UUID 생성
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        
        name = try container.decode(String.self, forKey: .name)
        part = try container.decode(String.self, forKey: .part)
        key = try container.decodeIfPresent(String.self, forKey: .key)
        sets = try container.decode([ExerciseSet].self, forKey: .sets)
        
        // restTime은 문자열이나 정수로 저장될 수 있음
        if let restTimeInt = try? container.decodeIfPresent(Int.self, forKey: .restTime) {
            restTime = restTimeInt
        } else if let restTimeString = try? container.decodeIfPresent(String.self, forKey: .restTime),
                  let restTimeInt = Int(restTimeString) {
            restTime = restTimeInt
        } else {
            restTime = nil
        }
    }
    
    init(id: String = UUID().uuidString, name: String, part: String, key: String? = nil, sets: [ExerciseSet], restTime: Int? = nil) {
        self.id = id
        self.name = name
        self.part = part
        self.key = key
        self.sets = sets
        self.restTime = restTime
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
