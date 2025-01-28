import SwiftUI

struct WorkoutDetailView: View {
    let workoutID: String // 전달받은 워크아웃 ID
    
    @StateObject private var viewModel = WorkoutDetailViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Workout Details")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let workout = viewModel.workout {
                Text("Name: \(workout.name)")
                    .font(.title2)
                
                Text("Scheduled Days: \(workout.scheduledDays.joined(separator: ", "))")
                    .font(.body)
                
                Text("Created At: \(workout.createdAt)")
                    .font(.body)
            } else {
                Text("Loading workout details...")
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            viewModel.fetchWorkoutDetails(workoutID: workoutID)
        }
    }
}
