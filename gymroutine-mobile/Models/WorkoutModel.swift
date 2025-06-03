//
//  WorkoutModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/01/28.
//

import Foundation
import FirebaseFirestore

// ワークアウトスケジュールタイプ
enum WorkoutScheduleType: String, Codable, CaseIterable {
    case oneTime = "oneTime"        // 一回限り
    case weekly = "weekly"          // 毎週繰り返し (特定曜日)
    case interval = "interval"      // 数日間隔で繰り返し
    case specificDates = "specificDates"  // 特定日付
    
    var displayName: String {
        switch self {
        case .oneTime: return "一回限り"
        case .weekly: return "毎週繰り返し"
        case .interval: return "間隔繰り返し"
        case .specificDates: return "特定日付"
        }
    }
}

// ワークアウト期間設定
struct WorkoutDuration: Codable {
    let totalSessions: Int?    // 総何回実行するか
    let weeks: Int?           // 総何週間継続するか
    let endDate: Date?        // 終了日
}

// ワークアウトスケジュール設定
struct WorkoutSchedule: Codable {
    let type: WorkoutScheduleType
    let weeklyDays: [String]?     // weeklyタイプの時の曜日 (Monday, Tuesday, ...)
    let intervalDays: Int?        // intervalタイプの時の日数間隔
    let startDate: Date?          // 開始日
    let specificDates: [Date]?    // specificDatesタイプの時の特定日付
}

struct Workout: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let name: String
    let createdAt: Date
    let notes: String?
    
    // 新しいスケジューリングシステム
    let schedule: WorkoutSchedule
    let duration: WorkoutDuration?
    
    // 既存フィールド (互換性のため維持)
    let isRoutine: Bool
    let scheduledDays: [String]
    
    let exercises: [WorkoutExercise]
    
    // コンストラクタ - 新しいスケジューリングシステム使用
    init(id: String? = nil,
         userId: String,
         name: String,
         createdAt: Date = Date(),
         notes: String? = nil,
         schedule: WorkoutSchedule,
         duration: WorkoutDuration? = nil,
         exercises: [WorkoutExercise]) {
        self.id = id
        self.userId = userId
        self.name = name
        self.createdAt = createdAt
        self.notes = notes
        self.schedule = schedule
        self.duration = duration
        self.exercises = exercises
        
        // 既存フィールド互換性のため自動設定
        self.isRoutine = schedule.type != .oneTime
        self.scheduledDays = schedule.weeklyDays ?? []
    }
    
    // 既存互換性のためのコンストラクタ
    init(id: String? = nil,
         userId: String,
         name: String,
         createdAt: Date = Date(),
         notes: String? = nil,
         isRoutine: Bool,
         scheduledDays: [String],
         exercises: [WorkoutExercise]) {
        self.id = id
        self.userId = userId
        self.name = name
        self.createdAt = createdAt
        self.notes = notes
        self.isRoutine = isRoutine
        self.scheduledDays = scheduledDays
        self.exercises = exercises
        
        // 既存データを新しいスケジュールシステムに変換
        if isRoutine {
            self.schedule = WorkoutSchedule(
                type: .weekly,
                weeklyDays: scheduledDays,
                intervalDays: nil,
                startDate: createdAt,
                specificDates: nil
            )
        } else {
            self.schedule = WorkoutSchedule(
                type: .oneTime,
                weeklyDays: nil,
                intervalDays: nil,
                startDate: createdAt,
                specificDates: nil
            )
        }
        self.duration = nil
    }
    
    static var mock: Workout {
        Workout(
            id: UUID().uuidString,
            userId: "mockUserId123",
            name: "Chest Day Workout",
            createdAt: Date(),
            notes: "Focus on form, not weight",
            schedule: WorkoutSchedule(
                type: .weekly,
                weeklyDays: ["Monday", "Thursday"],
                intervalDays: nil,
                startDate: Date(),
                specificDates: nil
            ),
            duration: WorkoutDuration(
                totalSessions: 12,
                weeks: 4,
                endDate: Calendar.current.date(byAdding: .weekOfYear, value: 4, to: Date())
            ),
            exercises: [
                WorkoutExercise.mock()
            ]
        )
    }
}
