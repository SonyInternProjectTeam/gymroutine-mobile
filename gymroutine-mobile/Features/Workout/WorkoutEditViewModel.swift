import SwiftUI

@MainActor
final class WorkoutEditViewModel: WorkoutExercisesManager {
    private let service = WorkoutService()
    
    @Published var workout: Workout
    @Published var showExerciseSearch = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    init(workout: Workout) {
        self.workout = workout
        super.init()
        self.exercises = workout.exercises
    }
    
    // 配列内のエクササイズの順序変更
    func moveExercise(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
    }
    
    // ワークアウト情報とエクササイズの順序を保存
    func saveWorkout(name: String, notes: String?, scheduledDays: [String]? = nil) async {
        UIApplication.showLoading()
        
        guard let workoutId = workout.id else {
            showError(message: "ワークアウトIDがありません")
            UIApplication.hideLoading()
            return
        }
        
        // 1. ワークアウト基本情報の更新
        let infoResult = await service.updateWorkoutInfo(
            workoutID: workoutId, 
            name: name, 
            notes: notes,
            scheduledDays: scheduledDays
        )
        
        // 2. エクササイズの順序を更新
        let exercisesResult = await service.reorderWorkoutExercises(workoutID: workoutId, exercises: exercises)
        
        UIApplication.hideLoading()
        
        // エラー処理
        switch infoResult {
        case .success:
            switch exercisesResult {
            case .success:
                // 成功
                UIApplication.showBanner(type: .success, message: "ワークアウトを更新しました")
                // ローカルワークアウトモデルの更新
                self.workout = Workout(
                    id: workout.id,
                    userId: workout.userId,
                    name: name,
                    createdAt: workout.createdAt,
                    notes: notes,
                    isRoutine: workout.isRoutine,
                    scheduledDays: scheduledDays ?? workout.scheduledDays,
                    exercises: exercises
                )
            case .failure(let error):
                showError(message: "エクササイズの更新に失敗しました: \(error.localizedDescription)")
            }
        case .failure(let error):
            showError(message: "ワークアウト情報の更新に失敗しました: \(error.localizedDescription)")
        }
    }
    
    // エラー表示
    private func showError(message: String) {
        self.errorMessage = message
        self.showError = true
        UIApplication.showBanner(type: .error, message: "更新に失敗しました")
    }
    
    // WorkoutExercisesManagerのappendExerciseをオーバーライド
    override func appendExercise(exercise: Exercise) {
        super.appendExercise(exercise: exercise)
        // 画面を閉じる
        showExerciseSearch = false
    }
} 