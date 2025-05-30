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
    
    func toPartName() -> String {
        return ExercisePart(rawValue: part)?.japaneseName ?? "その他"
    }

    func toDetailedPartName() -> String {
        return ExerciseDetailedPart(rawValue: detailedPart)?.japaneseName ?? "その他"
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

    // 日本語名の追加
    var japaneseName: String {
        switch self {
        case .arms: return "腕"
        case .abscore: return "腹筋・体幹"
        case .chest: return "胸"
        case .back: return "背中"
        case .lowerbody: return "下半身"
        case .shoulders: return "肩"
        }
    }
}


// 今後detailedPart検索機能実装の際に使用
enum ExerciseDetailedPart: String, CaseIterable {
    // Lower body
    case quadriceps = "quadriceps"         // 大腿四頭筋
    case adductors = "adductors"           // 内転筋
    case hamstrings = "hamstrings"         // ハムストリングス
    case glutes = "glutes"                 // 臀筋
    case calves = "calves"                 // ふくらはぎ（腓腹筋）

    // Chest
    case upperChest = "upper-chest"        // 上部胸筋
    case midChest = "mid-chest"            // 中部胸筋
    case lowerChest = "lower-chest"        // 下部胸筋

    // Back
    case lats = "lats"                     // 広背筋
    case midBack = "mid-back"              // 背中中央
    case traps = "traps"                   // 僧帽筋
    case lowerBack = "lower-back"          // 下背部

    // Shoulders
    case anteriorDeltoid = "anterior-deltoid"   // 前部三角筋
    case lateralDeltoid = "lateral-deltoid"     // 側部三角筋
    case posteriorDeltoid = "posterior-deltoid" // 後部三角筋

    // Arms
    case biceps = "biceps"                 // 上腕二頭筋
    case triceps = "triceps"               // 上腕三頭筋
    case forearms = "forearms"             // 前腕筋

    // Abs
    case rectusAbdominis = "rectus-abdomini"   // 腹直筋
    case obliques = "obliques"                 // 腹斜筋
    case deepCore = "deep-core"                // 深層筋（インナーユニット）

    var japaneseName: String {
        switch self {
        case .quadriceps: return "大腿四頭筋"
        case .adductors: return "内転筋"
        case .hamstrings: return "ハムストリングス"
        case .glutes: return "臀筋"
        case .calves: return "ふくらはぎ"

        case .upperChest: return "上部胸筋"
        case .midChest: return "中部胸筋"
        case .lowerChest: return "下部胸筋"

        case .lats: return "広背筋"
        case .midBack: return "背中中央"
        case .traps: return "僧帽筋"
        case .lowerBack: return "下背部"

        case .anteriorDeltoid: return "前部三角筋"
        case .lateralDeltoid: return "側部三角筋"
        case .posteriorDeltoid: return "後部三角筋"

        case .biceps: return "上腕二頭筋"
        case .triceps: return "上腕三頭筋"
        case .forearms: return "前腕筋"

        case .rectusAbdominis: return "腹直筋"
        case .obliques: return "腹斜筋"
        case .deepCore: return "深層筋"
        }
    }
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
  
    func toPartName() -> String {
        return ExercisePart(rawValue: part)?.japaneseName ?? "その他"
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
