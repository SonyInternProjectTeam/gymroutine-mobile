import SwiftUI
import FirebaseFirestore

// 템플릿 상세 보기
struct TemplateDetailView: View {
    let template: WorkoutTemplate
    @StateObject private var viewModel: TemplateDetailViewModel
    @Environment(\.presentationMode) var presentationMode
    
    init(template: WorkoutTemplate) {
        self.template = template
        _viewModel = StateObject(wrappedValue: TemplateDetailViewModel(template: template))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 헤더 정보
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(template.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        if template.isPremium {
                            Label("Premium", systemImage: "star.fill")
                                .font(.subheadline)
                                .foregroundColor(.yellow)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.yellow.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    
                    HStack {
                        Label(template.level, systemImage: "chart.bar")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        
                        Label(template.duration, systemImage: "clock")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Text("日程: \(template.scheduledDays.joined(separator: ", "))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let notes = template.notes {
                        Text(notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                }
                .padding(.horizontal)
                
                // 운동 목록
                Text("エクササイズ")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                ForEach(template.exercises, id: \.id) { exercise in
                    ExerciseCard(exercise: exercise)
                        .padding(.horizontal)
                }
                
                // 시작 버튼
                Button(action: {
                    viewModel.addTemplateToUserWorkouts { success in
                        if success {
                            // 성공 시 추가 작업이 필요하면 여기에 구현
                        }
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    } else {
                        Text("このテンプレートを使う")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .disabled(viewModel.isLoading)
                .padding()
            }
            .padding(.vertical)
        }
        .navigationTitle("テンプレート詳細")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK")) {
                    if viewModel.alertTitle.contains("完了") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
    }
}

// 운동 카드 컴포넌트
struct ExerciseCard: View {
    let exercise: WorkoutExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(exercise.name)
                    .font(.headline)
                
                Spacer()
                
                Text(exercise.part.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Divider()
            
            ForEach(0..<exercise.sets.count, id: \.self) { index in
                HStack {
                    Text("Set \(index + 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(exercise.sets[index].reps) reps")
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    if exercise.sets[index].weight > 0 {
                        Text("\(Int(exercise.sets[index].weight)) kg")
                    } else {
                        Text("重量")
                    }
                }
                .font(.subheadline)
            }
            
            if let restTime = exercise.restTime {
                HStack {
                    Text("休憩:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(restTime) 秒")
                        .font(.caption)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.vertical, 4)
    }
} 