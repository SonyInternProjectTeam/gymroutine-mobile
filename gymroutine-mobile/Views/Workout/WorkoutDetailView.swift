import SwiftUI

struct WorkoutDetailView: View {
    let workoutID: String
    
    @StateObject private var viewModel = WorkoutDetailViewModel()
    @State private var navigateToExerciseSearch = false
    
    // 数値入力用の NumberFormatter（整数表示）
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }
    
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
                
                Text("作成日: \(workout.createdAt, formatter: dateFormatter)")
                    .font(.body)
            } else {
                Text("ワークアウトの詳細を読み込み中...")
                    .foregroundColor(.gray)
            }
            
            // エクササイズリスト
            List {
                ForEach(viewModel.exercises.indices, id: \.self) { index in
                    let exercise = viewModel.exercises[index]
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.name)
                            .font(.headline)
                        
                        Text("部位: \(exercise.part)")
                            .font(.subheadline)
                        
                        // 各セットの情報を表示
                        if exercise.sets.isEmpty {
                            Text("セットがありません")
                                .foregroundColor(.gray)
                        } else {
                            // ForEachでは、enumerated() を用いて各セットのインデックスと要素を取得する
                            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { (setIndex, setItem) in
                                HStack {
                                    Text("Set \(setIndex + 1):")
                                        .font(.subheadline)
                                    
                                    Text("回数:")
                                        .font(.caption)
                                    TextField("0", value: Binding(
                                        get: {
                                            setItem.reps
                                        },
                                        set: { newValue in
                                            if let actualIndex = viewModel.exercises[index].sets.firstIndex(where: { $0.id == setItem.id }) {
                                                viewModel.exercises[index].sets[actualIndex].reps = newValue
                                            }
                                        }
                                    ), formatter: numberFormatter)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 50)
                                    
                                    Text("重量:")
                                        .font(.caption)
                                    TextField("0", value: Binding(
                                        get: {
                                            setItem.weight
                                        },
                                        set: { newValue in
                                            if let actualIndex = viewModel.exercises[index].sets.firstIndex(where: { $0.id == setItem.id }) {
                                                viewModel.exercises[index].sets[actualIndex].weight = newValue
                                            }
                                        }
                                    ), formatter: numberFormatter)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 50)
                                    
                                    // セット削除ボタン
                                    Button(action: {
                                        viewModel.deleteExerciseSet(workoutID: workoutID, exerciseID: exercise.id, setID: UUID(uuidString: setItem.id) ?? UUID())
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    
                                }
                            }
                        }
                        
                        // セット追加ボタン
                        Button(action: {
                            // ここでは単純히 새로운 세트를 추가합니다.
                            viewModel.exercises[index].sets.append(ExerciseSet(reps: 0, weight: 0))
                        }) {
                            Text("セット追加")
                                .font(.subheadline)
                                .padding(5)
                                .frame(maxWidth: .infinity)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(5)
                        }
                        
                        // Firestore に更新するボタン
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
            
            // エクササイズ追加ボタン
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
            
            // ExerciseSearchView への遷移
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
    
    // 日付表示用の DateFormatter
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}
