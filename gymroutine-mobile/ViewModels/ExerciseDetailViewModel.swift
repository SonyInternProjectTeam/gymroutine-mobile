import Foundation

class ExerciseDetailViewModel: ObservableObject {
    private let workoutService = WorkoutService()
    
    /// 워크아웃에 운동을 추가하는 메서드 (WorkoutExercise 객체를 인자로 받음)
    func addExerciseToWorkout(workoutID: String, exercise: WorkoutExercise, completion: @escaping (Bool) -> Void) {
        workoutService.addExerciseToWorkout(workoutID: workoutID, exercise: exercise) { success in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
}
