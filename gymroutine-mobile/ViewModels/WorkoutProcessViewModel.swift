import Combine
import Foundation

class WorkoutProcessViewModel: ObservableObject {
    @Published var exercises: [[String: Any]] = []
    @Published var timerValue: Int = 0
    private var timer: AnyCancellable?
    private var isTimerRunning = false

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

    func addSet(toExerciseAt exerciseIndex: Int) {
        guard exerciseIndex >= 0, exerciseIndex < exercises.count else { return }
        var exercise = exercises[exerciseIndex]
        var sets = exercise["Sets"] as? [[String: Any]] ?? []

        let newSet: [String: Any] = [
            "Reps": 0,
            "Weight": 0,
            "isDone": false
        ]

        sets.append(newSet)
        exercise["Sets"] = sets
        exercises[exerciseIndex] = exercise

        objectWillChange.send()
    }

    func removeSet(fromExerciseAt exerciseIndex: Int, setIndex: Int) {
        guard exerciseIndex >= 0, exerciseIndex < exercises.count else { return }
        guard var exercise = exercises[exerciseIndex] as? [String: Any],
              var sets = exercise["Sets"] as? [[String: Any]],
              setIndex >= 0, setIndex < sets.count else { return }

        sets.remove(at: setIndex)
        exercise["Sets"] = sets
        exercises[exerciseIndex] = exercise

        objectWillChange.send()
    }

    func getTotalExerciseCount() -> Int {
        return exercises.count
    }

    func startTimer() {
        guard !isTimerRunning else { return }
        isTimerRunning = true
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.timerValue += 1
            }
    }

    func stopTimer() {
        isTimerRunning = false
        timer?.cancel()
        timer = nil
    }

    func resetTimer() {
        stopTimer()
        timerValue = 0
    }
}
