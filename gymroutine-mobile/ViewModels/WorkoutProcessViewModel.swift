import Foundation

class WorkoutProcessViewModel: ObservableObject {
    @Published var exercises: [[String: Any]] = []

    init(exercises: [[String: Any]]) {
        self.exercises = exercises
    }

    func getExercise(at index: Int) -> [String: Any]? {
        guard index >= 0 && index < exercises.count else {
            return nil
        }
        return exercises[index]
    }

    func updateSetValue(exerciseIndex: Int, setIndex: Int, key: String, newValue: Any) {
        guard exerciseIndex >= 0, exerciseIndex < exercises.count else { return }
        guard var exercise = exercises[exerciseIndex] as? [String: Any],
              var sets = exercise["Sets"] as? [[String: Any]],
              setIndex >= 0, setIndex < sets.count else { return }

        sets[setIndex][key] = newValue
        exercise["Sets"] = sets
        exercises[exerciseIndex] = exercise

        objectWillChange.send()
    }

    func getTotalExerciseCount() -> Int {
        return exercises.count
    }
}
