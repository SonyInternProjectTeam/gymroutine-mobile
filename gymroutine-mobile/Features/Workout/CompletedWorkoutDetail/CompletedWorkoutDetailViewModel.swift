//
//  CompletedWorkoutDetailViewModel.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2025/05/01
//  
//


import Foundation

@MainActor
final class CompletedWorkoutDetailViewModel: ObservableObject {
    @Published var workoutResult: WorkoutResult?
    @Published var workoutName: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    //合計セット数
    var totalSets: Int {
        workoutResult?.exercises?.reduce(0) { $0 + ($1.sets?.count ?? 0) } ?? 0
    }
    
    // 総重量
    var totalVolume: Int {
        workoutResult?.exercises?.flatMap { $0.sets ?? [] }
            .reduce(0) { sum, set in
                let reps = set.reps ?? 0
                let weight = set.weight ?? 0
                return sum + Int(Double(reps) * weight)
            } ?? 0
    }
    
    private let resultService = ResultService()
    private let workoutService = WorkoutService()
    
    func loadWorkoutResult(resultId: String) {
        isLoading = true
        
        Task {
            let result = await resultService.fetchWorkoutResultDetail(resultId: resultId)
            
            // 워크아웃 결과를 가져온 후, 해당 워크아웃 ID가 있다면 워크아웃 이름도 가져옴
            if let result = result, let workoutId = result.workoutId {
                let response = await workoutService.fetchWorkoutById(workoutID: workoutId)
                switch response {
                case .success(let workout):
                    self.workoutName = workout.name
                case .failure(let error):
                    print("[ERROR] \(error.localizedDescription)")
                    // ワークアウト名がない場合はエクササイズ名を使用
                    if let firstExercise = result.exercises?.first {
                        self.workoutName = firstExercise.exerciseName + "のワークアウト"
                    } else {
                        self.workoutName = "Quick Start"
                    }
                }
            } else {
                DispatchQueue.main.async {
                    
                    if result == nil {
                        self.errorMessage = "ワークアウト結果の読み込みに失敗しました"
                    } else if let exercises = result?.exercises, !exercises.isEmpty {
                        // ワークアウトIDがなく、エクササイズがある場合
                        self.workoutName = exercises[0].exerciseName + "のワークアウト"
                    } else {
                        self.workoutName = "Quick Start"
                    }
                }
            }
            self.workoutResult = result
            self.isLoading = false
        }
    }
    
    func formattedTime(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes)分 \(remainingSeconds)秒"
    }
}
