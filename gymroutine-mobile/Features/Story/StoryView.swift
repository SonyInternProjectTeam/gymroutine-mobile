import SwiftUI
import FirebaseFirestore // Import Firestore to use Timestamp
// import Kingfisher // Assuming you use Kingfisher for image loading

struct StoryView: View {
    @StateObject var viewModel: StoryViewModel
    @Environment(\.dismiss) var dismiss // To close the view

    var body: some View {
        NavigationView { // Keep NavigationView for potential title/toolbar
            ZStack(alignment: .topLeading) { // Align top leading for content
                Color.black.ignoresSafeArea()

                // Content Area
                VStack(alignment: .leading) {
                    // User Info and Close Button (Top Bar)
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .foregroundColor(.white.opacity(0.8))
                        VStack(alignment: .leading) {
                            Text(viewModel.user.name)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            // Display story creation time or relative time if available
                            if stories.indices.contains(viewModel.currentStoryIndex) {
                                let story = stories[viewModel.currentStoryIndex]
                                Text(story.createdAt.dateValue(), style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 5) // Adjust padding as needed

                    // Progress Bars
                    HStack {
                        ForEach(0..<viewModel.stories.count, id: \.self) { index in
                            ProgressBar(isCurrent: index == viewModel.currentStoryIndex)
                                // TODO: Add animation/timer logic here
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10) // Add padding below progress bars

                    // Workout Result Display Area
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let workoutResult = viewModel.workoutResult {
                        WorkoutResultDetailView(result: workoutResult)
                            .padding(.horizontal) // Add padding for the result view
                    } else if let errorMessage = viewModel.errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                    } else {
                         // Placeholder if no result is loaded (e.g., fetchWorkoutResult needs implementation)
                        Text("Workout result details will appear here.")
                             .foregroundColor(.gray)
                             .frame(maxWidth: .infinity, maxHeight: .infinity)
                             .padding()
                    }
                    
                    Spacer() // Pushes content to the top
                }
                
                // Tap zones for navigation (overlay the whole ZStack)
                HStack {
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { viewModel.previousStory() }
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { viewModel.advanceStory() }
                }
                .ignoresSafeArea() // Ensure tap zones cover screen edges
            }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
        }
    }
    
    // Access stories from viewModel to prevent compiler errors
    private var stories: [Story] {
        viewModel.stories
    }
}

// Simple Progress Bar View (Customize as needed)
struct ProgressBar: View {
    var isCurrent: Bool
    // Add progress state if you want animation

    var body: some View {
        Rectangle()
            .fill(isCurrent ? Color.white.opacity(0.8) : Color.gray.opacity(0.5))
            .frame(height: 3)
            .clipShape(Capsule())
    }
}

// New View to display Workout Result details
struct WorkoutResultDetailView: View {
    let result: WorkoutResultModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("ワークアウト概要") // "Workout Summary"
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                HStack {
                    Text("合計時間:") // "Total Time:"
                        .foregroundColor(.gray)
                    Text("\(formatDuration(result.duration))")
                        .foregroundColor(.white)
                    Spacer()
                    // Add Rest Time if available
                    // if let restTime = result.restTime {
                    //     Text("休憩時間: \(formatDuration(restTime))")
                    //         .foregroundColor(.gray)
                    // }
                }
                
                Divider().background(Color.gray)

                Text("実行したエクササイズ") // "Exercises Performed"
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                ForEach(result.exercises, id: \.self) { exercise in
                    VStack(alignment: .leading) {
                        Text(exercise.exerciseName)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        ForEach(exercise.sets.indices, id: \.self) { index in
                            let set = exercise.sets[index]
                            HStack {
                                Text("セット \(index + 1):")
                                    .foregroundColor(.gray)
                                Text("\(set.Reps) 回") // "reps"
                                if let weight = set.Weight {
                                    Text("@ \(weight, specifier: "%.1f") kg") // Format weight
                                }
                            }
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(.bottom, 5)
                }
                
                if let notes = result.notes, !notes.isEmpty {
                     Divider().background(Color.gray)
                     Text("メモ") // "Notes"
                         .font(.title3)
                         .fontWeight(.semibold)
                         .foregroundColor(.white)
                     Text(notes)
                         .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .foregroundColor(.white) // Default text color for the ScrollView content
    }
    
    // Helper function to format duration (e.g., seconds to MM:SS)
    private func formatDuration(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Preview Provider (Updated)
struct StoryView_Previews: PreviewProvider {
    static var previews: some View {
        let mockUser = User(uid: "previewUser1", email: "preview@example.com", name: "Preview User")
        // Create mock workout result data
        let mockSet1 = SetResultModel(Reps: 10, Weight: 50.0)
        let mockSet2 = SetResultModel(Reps: 8, Weight: 55.0)
        let mockExercise1 = ExerciseResultModel(exerciseName: "ベンチプレス", setsCompleted: 2, sets: [mockSet1, mockSet2])
        let mockExercise2 = ExerciseResultModel(exerciseName: "ショルダープレス", setsCompleted: 3, sets: [mockSet1, mockSet1, mockSet1])
        let mockWorkoutResult = WorkoutResultModel(
            id: "mockResult1",
            duration: 2700, // 45 minutes in seconds
            restTime: nil,
            workoutID: "origWorkout1",
            exercises: [mockExercise1, mockExercise2],
            notes: "今日のトレーニングは順調でした！",
            createdAt: Timestamp(date: Date())
        )
        
        let mockStories = [
            Story(id: "story1", userId: "previewUser1", photo: nil, expireAt: Timestamp(date: Date(timeIntervalSinceNow: 3600)), isExpired: false, visibility: 1, workoutId: "mockResult1", createdAt: Timestamp(date: Date())),
            Story(id: "story2", userId: "previewUser1", photo: nil, expireAt: Timestamp(date: Date(timeIntervalSinceNow: 7200)), isExpired: false, visibility: 1, workoutId: "anotherResultId", createdAt: Timestamp(date: Date()))
        ]
        
        let viewModel = StoryViewModel(user: mockUser, stories: mockStories)
        // Manually set the workoutResult for the preview since fetching is not implemented yet
        viewModel.workoutResult = mockWorkoutResult 
        
        return StoryView(viewModel: viewModel)
    }
} 
