// gymroutine-mobile/Models/WorkoutResultModel.swift
import Foundation
import FirebaseFirestore


// Firestore 'sets' 배열 항목
struct SetResultModel: Codable, Hashable {
    let Reps: Int // Firestore 필드명과 일치
    let Weight: Double? // Firestore 필드명과 일치 (null 가능)
}

// Firestore 'exercises' 배열 항목
struct ExerciseResultModel: Codable, Hashable {
    let exerciseName: String
    let setsCompleted: Int
    let sets: [SetResultModel]
}

// Firestore 'Result/{userID}/{YYYYMM}/{YYYYMMDD}' 문서
struct WorkoutResultModel: Codable, Identifiable {
    @DocumentID var id: String? // Firestore 문서 ID (YYYYMMDD 형식)
    let duration: Int // 총 운동 시간 (초 또는 분)
    let restTime: Int? // TODO: 총 휴식 시간 (추적 및 계산 필요)
    let workoutID: String? // 원래 Workout의 ID (Workouts 컬렉션 참조)
    let exercises: [ExerciseResultModel]
    var notes: String? // << 노트 필드를 var로 변경 (뷰에서 수정 가능하도록)
    let createdAt: Timestamp // 완료 시간 -> 생성 시간으로 필드명 변경

    // CodingKeys를 사용하여 Firestore 필드명과 Swift 프로퍼티명을 매핑할 수 있습니다.
    // 여기서는 Swift 프로퍼티명을 Firestore 필드명과 일치시켰으므로 생략 가능합니다.
} 
