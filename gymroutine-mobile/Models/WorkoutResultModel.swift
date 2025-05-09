// gymroutine-mobile/Models/WorkoutResultModel.swift
import Foundation
import FirebaseFirestore

// Firestoreの「Result」コレクションのドキュメントをマッピングするモデル
struct WorkoutResult: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String?
    var workoutId: String?
    var workoutName: String?
    var createdAt: Timestamp?
    var duration: Int?
    var exercises: [ExerciseResult]?
    var memo: String?
    var restTime: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case workoutId = "workoutID"
        case workoutName
        case createdAt
        case duration
        case exercises
        case memo = "notes"
        case restTime
    }
}

// エクササイズ結果モデル
struct ExerciseResult: Codable, Identifiable {
    var id: String { exerciseName }
    var exerciseName: String
    var key: String // CalenderViewアイコン表示用
    var sets: [ExerciseSetResult]?
    var setsCompleted: Int?
    
    enum CodingKeys: String, CodingKey {
        case exerciseName
        case key
        case sets
        case setsCompleted
    }
    
    // Firestoreからのデコード用
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        exerciseName = try container.decode(String.self, forKey: .exerciseName)
        setsCompleted = try? container.decode(Int.self, forKey: .setsCompleted)
        
        // setsをデコード
        if let rawSets = try? container.decode([SetResultModel].self, forKey: .sets) {
            // SetResultModelからExerciseSetResultへ変換
            sets = rawSets.map { rawSet in
                ExerciseSetResult(
                    weight: rawSet.Weight,
                    reps: rawSet.Reps
                )
            }
        } else {
            sets = nil
        }
    }
}

// セット結果モデル
struct ExerciseSetResult: Codable {
    var weight: Double?
    var reps: Int?
    
    enum CodingKeys: String, CodingKey {
        case weight = "Weight"
        case reps = "Reps"
    }
}

// Firestoreの'sets'配列アイテム（生データ構造）
struct SetResultModel: Codable, Hashable {
    let Reps: Int
    let Weight: Double?
}

// Firestoreの'exercises'配列アイテム（生データ構造）
struct ExerciseResultModel: Codable, Hashable {
    let exerciseName: String
    let key : String
    let setsCompleted: Int
    let sets: [SetResultModel]
    
    static var mock: ExerciseResultModel {
        ExerciseResultModel(
            exerciseName: "ベンチプレス",
            key: "Bench Press",
            setsCompleted: 3,
            sets: [
                SetResultModel(Reps: 10, Weight: 50.0),
                SetResultModel(Reps: 8, Weight: 55.0),
                SetResultModel(Reps: 6, Weight: 60.0)
            ]
        )
    }
}

// 注意: このモデルは古い構造です。代わりにWorkoutResultを使用してください
@available(*, deprecated, message: "Use WorkoutResult instead")
struct WorkoutResultModel: Codable, Identifiable {
    @DocumentID var id: String?
    let duration: Int
    let restTime: Int?
    let workoutID: String?
    let exercises: [ExerciseResultModel]
    var notes: String?
    let createdAt: Timestamp
} 
