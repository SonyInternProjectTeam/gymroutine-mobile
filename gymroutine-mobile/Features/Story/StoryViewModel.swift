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

    private var cancellables = Set<AnyCancellable>()
    private let workoutService = WorkoutService() // Assuming WorkoutService fetches results

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
            currentStoryIndex += 1
        } else {
            // Optionally close the story view or loop back
            // closeStoryView() // Needs implementation
        }
    }

    func previousStory() {
        if currentStoryIndex > 0 {
            currentStoryIndex -= 1
        }
    }

    // TODO: Implement logic for story timer/progress bar
    // TODO: Add function to mark a story as viewed if necessary
} 