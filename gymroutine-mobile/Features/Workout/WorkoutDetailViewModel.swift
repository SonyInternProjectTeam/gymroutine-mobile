//
//  WorkoutDetailViewModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/04/01.
//

import SwiftUI

final class WorkoutDetailViewModel: ObservableObject {
    @Published var workout: Workout
    @Published var exercises: [WorkoutExercise]
    
    init(workout: Workout) {
        self.workout = workout
        self.exercises = workout.exercises
    }
    
    /// 워크아웃 편집 액션 (예: 편집 화면으로 이동)
    func editWorkout() {
        // 실제 편집 로직 구현 (예: 편집 모드 전환 혹은 편집 화면으로 푸시)
        print("Edit workout tapped")
    }
    
    /// 새 운동 추가 액션
    func addExercise() {
        // 예시: 새 운동을 임시로 추가 (실제 구현 시 추가 화면으로 이동하거나 모달을 표시)
        let newExercise = WorkoutExercise(
            id: UUID().uuidString,
            name: "新しいエクササイズ",
            part: "部位",
            sets: []  // 초기에는 빈 세트 배열
        )
        exercises.append(newExercise)
        print("Add exercise tapped")
    }
    
    /// 워크아웃 시작 액션
    func startWorkout() {
        // 워크아웃 시작에 관한 처리 (예: 워크아웃 타이머 시작, 기록 화면 전환 등)
        print("Start workout tapped")
    }
}
