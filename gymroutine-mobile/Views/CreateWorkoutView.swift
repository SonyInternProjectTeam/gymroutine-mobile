import SwiftUI

struct CreateWorkoutView: View {
    @ObservedObject var viewModel = WorkoutViewModel()
    @State private var selectedTrain: String? = nil
    @State private var selectedExercise: String? = nil
    
    // 曜日の選択状態を管理する辞書
    @State private var selectedDays: [String: Bool] = [
        "Monday": false,
        "Tuesday": false,
        "Wednesday": false,
        "Thursday": false,
        "Friday": false,
        "Saturday": false,
        "Sunday": false
    ]
    
    // ワークアウト名を入力する状態変数
    @State private var workoutName: String = ""
    
    var body: some View {
        VStack {
            Text("Select details")
                .font(.title)
                .padding()
            // ワークアウト名の入力フィールド
            TextField("Enter Workout Name", text: $workoutName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            // 曜日選択部分
            VStack {
                Text("Select Days")
                    .font(.headline)
                
                HStack {
                    ForEach(selectedDays.keys.sorted(), id: \.self) { day in
                        Button(action: {
                            selectedDays[day]?.toggle()
                        }) {
                            Text(day.prefix(3)) // 月, 火, 水...
                                .font(.caption)
                                .padding()
                                .background(selectedDays[day]! ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            Spacer()
            
            // Create Workoutボタン
            Button(action: {
                viewModel.createWorkoutWithDetails(name: workoutName, selectedDays: selectedDays)
            }) {
                Text("Go to Exsercise select")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .disabled(workoutName.isEmpty) // ワークアウト名が空ならボタンを無効化
            
        }
        .onAppear {
            viewModel.createWorkout()
        }
        .navigationTitle("Create Workout")
    }
}

#Preview {
    CreateWorkoutView()
}
