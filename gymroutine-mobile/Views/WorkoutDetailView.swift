import SwiftUI

struct WorkoutDetailView: View {
    let workoutID: String
    
    @StateObject private var viewModel = WorkoutDetailViewModel()
    @State private var navigateToExerciseSearch = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("ワークアウトの詳細")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let workout = viewModel.workout {
                Text("名前: \(workout.name)")
                    .font(.title2)
                
                Text("スケジュールされた日: \(workout.scheduledDays.joined(separator: ", "))")
                    .font(.body)
                
                Text("作成日: \(workout.createdAt)")
                    .font(.body)
            } else {
                Text("ワークアウトの詳細を読み込み中...")
                    .foregroundColor(.gray)
            }
            
            // ✅ エクササイズリスト (sets, reps, weight の編集が可能)
            List {
                ForEach(viewModel.exercises.indices, id: \.self) { index in
                    let exercise = viewModel.exercises[index]
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.name)
                            .font(.headline)
                        
                        Text("部位: \(exercise.part)")
                            .font(.subheadline)
                        
                        HStack {
                            Text("セット数:")
                            TextField("0", value: $viewModel.exercises[index].sets, formatter: NumberFormatter())
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 50)
                            
                            Text("回数:")
                            TextField("0", value: $viewModel.exercises[index].reps, formatter: NumberFormatter())
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 50)
                            
                            Text("重量:")
                            TextField("0", value: $viewModel.exercises[index].weight, formatter: NumberFormatter())
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 50)
                        }
                        
                        // ✅ Firestoreに更新するボタン
                        Button(action: {
                            viewModel.updateExercise(workoutID: workoutID, updatedExercise: viewModel.exercises[index])
                        }) {
                            Text("更新する")
                                .font(.subheadline)
                                .padding(5)
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(5)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Spacer()
            
            // ✅ エクササイズ追加ボタン
            Button(action: {
                navigateToExerciseSearch = true
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
            
            // ✅ ExerciseSearchViewへ遷移
            NavigationLink(
                destination: ExerciseSearchView(workoutID: workoutID),
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
