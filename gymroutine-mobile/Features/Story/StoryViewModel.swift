import Foundation
import Combine
import FirebaseFirestore // For Timestamp

@MainActor
class StoryViewModel: ObservableObject {
    @Published var user: User // The user whose stories are being viewed
    @Published var stories: [Story] = []
    @Published var currentStoryIndex: Int = 0 {
        didSet {
            fetchWorkoutResult()
        }
    }
    @Published var workoutResult: WorkoutResultModel? = nil // To hold the fetched workout result
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    //ViewModelからViewを閉じる
    var viewDismissalModePublisher = PassthroughSubject<Bool, Never>()
    private var shouldDismissView = false {
        didSet {
            viewDismissalModePublisher.send(shouldDismissView)
        }
    }

    private var cancellables = Set<AnyCancellable>()
    private let workoutService = WorkoutService() // Assuming WorkoutService fetches results
    
    // 合計セット数
    var totalSets: Int {
        guard let workoutResult = workoutResult else { return 0 }
        
        var total = 0
        for exercise in workoutResult.exercises {
            total += exercise.sets.count
        }
        return total
    }
    
    // 総重量
    var totalVolume: Int {
        guard let workoutResult = workoutResult else { return 0 }
        
        var total = 0
        for exercise in workoutResult.exercises {
            for set in exercise.sets {
                let weight = set.Weight ?? 0.0
                total += Int(Double(set.Reps) * weight)
            }
        }
        return total
    }

    init(user: User, stories: [Story]) {
        self.user = user
        self.stories = stories
        fetchWorkoutResult() // Fetch result for the initial story
        // Start timer or logic to advance stories if needed
    }

    private func fetchWorkoutResult() {
        guard stories.indices.contains(currentStoryIndex) else { 
            self.workoutResult = nil
            return 
        }
        let story = stories[currentStoryIndex]
        
        // workoutId is non-optional in StoryModel, so directly access it.
        let workoutResultId = story.workoutId 
        // guard let workoutResultId = story.workoutId else {
        //     errorMessage = "Workout Result ID not found in story."
        //     workoutResult = nil
        //     return
        // }
        
        // Calculate the month (YYYYMM) from the story's createdAt timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMM"
        let monthString = dateFormatter.string(from: story.createdAt.dateValue()) // Use story's createdAt
        let userId = story.userId // Get userId from the story

        // Start fetching
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await workoutService.fetchWorkoutResultById(
                    userId: userId, 
                    month: monthString, 
                    resultId: workoutResultId
                )
                // Update on the main thread
                await MainActor.run {
                    self.workoutResult = result
                    self.isLoading = false
                }
            } catch {
                // Update on the main thread
                await MainActor.run {
                    self.errorMessage = "Failed to load workout result: \(error.localizedDescription)"
                    self.workoutResult = nil
                    self.isLoading = false
                    print("Error fetching workout result for story: \(story.id ?? "N/A") - UserId: \(userId), Month: \(monthString), ResultId: \(workoutResultId) Error: \(error)")
                }
            }
        }
    }

    func advanceStory() {
        if currentStoryIndex < stories.count - 1 {
            print("DEBUG: 次のストーリーを表示します。")
            currentStoryIndex += 1
        } else {
            shouldDismissView = true
        }
    }

    func previousStory() {
        if currentStoryIndex > 0 {
            print("DEBUG: 前のストーリーを表示します。")
            currentStoryIndex -= 1
        } else {
            shouldDismissView = true
        }
    }

    func formattedTime(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes)分 \(remainingSeconds)秒"
    }
} 
