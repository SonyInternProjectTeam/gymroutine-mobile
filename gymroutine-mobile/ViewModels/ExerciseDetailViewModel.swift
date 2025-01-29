import Foundation

class ExerciseDetailViewModel: ObservableObject {
    private let workoutService = WorkoutService()
    
    /// 워크아웃에 운동을 추가하는 메서드
    func addExerciseToWorkout(workoutID: String, exerciseName: String, part: String, completion: @escaping (Bool) -> Void) {
        workoutService.addExerciseToWorkout(workoutID: workoutID, exerciseName: exerciseName, part: part) { success in
            DispatchQueue.main.async {
                completion(success) // UI 업데이트를 위해 메인 스레드에서 실행
            }
        }
    }
}

