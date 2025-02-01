import SwiftUI

struct CreateWorkoutView: View {
    @ObservedObject var viewModel = CreateWorkoutViewModel()
    @State private var workoutName: String = ""
    @State private var selectedDays: [String: Bool] = [
        "Monday": false, "Tuesday": false, "Wednesday": false,
        "Thursday": false, "Friday": false, "Saturday": false, "Sunday": false
    ]
    
    @State private var createdWorkoutID: String? = nil
    @State private var navigateToDetailView = false
    
    var body: some View {
        VStack {
            Text("ワークアウト作成")
                .font(.title)
                .padding()
            
            TextField("Enter Workout Name", text: $workoutName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // 요일 선택 버튼
            VStack {
                Text("Select Days").font(.headline)
                HStack {
                    ForEach(selectedDays.keys.sorted(), id: \.self) { day in
                        Button(action: {
                            selectedDays[day]?.toggle()
                        }) {
                            Text(day.prefix(3))
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

            // 🔹 버튼: 워크아웃 생성 후 상세 화면으로 이동
            Button(action: {
                viewModel.createWorkoutWithDetails(name: workoutName, selectedDays: selectedDays) { workoutID in
                    if let workoutID = workoutID {
                        DispatchQueue.main.async {
                            self.createdWorkoutID = workoutID
                            self.navigateToDetailView = true
                        }
                    } else {
                        print("Failed to create workout.")
                    }
                }
            }) {
                Text("ルーティン生成")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(workoutName.isEmpty ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .disabled(workoutName.isEmpty) // 워크아웃 이름이 비어있으면 비활성화

            // 🔹 NavigationLink: 생성된 workoutID가 있으면 상세 화면으로 전환
            NavigationLink(
                destination: WorkoutDetailView(workoutID: createdWorkoutID ?? ""),
                isActive: $navigateToDetailView
            ) {
                EmptyView()
            }
        }
        .padding()
        .navigationTitle("Create Workout")
    }
}
