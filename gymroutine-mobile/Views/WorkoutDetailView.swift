import SwiftUI

struct WorkoutDetailView: View {
    let workoutID: String // 전달받은 워크아웃 ID
    
    @StateObject private var viewModel = WorkoutDetailViewModel()
    @State private var navigateToExerciseSearch = false // 네비게이션 플래그
    
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
            
            // Exercise 추가 버튼
            Button(action: {
                navigateToExerciseSearch = true // 버튼을 누르면 네비게이션 플래그 설정
            }) {
                Text("エクササイズを追加")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            Spacer()
            
            // NavigationLink로 ExerciseSearchView로 이동하면서 workoutID 전달
            NavigationLink(
                destination: ExerciseSearchView(workoutID: workoutID), // ✅ workoutID 
                isActive: $navigateToExerciseSearch
            ) {
                EmptyView()
            }
        }
        .padding()
        .onAppear {
            viewModel.fetchWorkoutDetails(workoutID: workoutID)
        }
    }
}
