//
//  WorkoutModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/01/28.
//

import Foundation

struct Workout: Identifiable, Codable {
    let id: String               // Firestore 문서 ID
    let userId: String           // 사용자 ID
    let name: String             // 워크아웃 이름
    let isRoutine: Bool          // 루틴 여부
    let scheduledDays: [String]  // 선택된 요일 (예: ["Monday", "Wednesday", "Friday"])
    let exercises: [WorkoutExercise] // 운동 목록
    let createdAt: Date          // 생성 시각
    let notes: String?           // 메모 혹은 추가 코멘트
}
