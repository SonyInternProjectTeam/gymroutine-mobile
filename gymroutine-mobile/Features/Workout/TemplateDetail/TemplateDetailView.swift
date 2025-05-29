import SwiftUI
import FirebaseFirestore

// 템플릿 상세 보기
struct TemplateDetailView: View {
    let template: WorkoutTemplate
    var localizedScheduledDays: String {
        let dayMap: [String: String] = [
            "Sunday": "日",
            "Monday": "月",
            "Tuesday": "火",
            "Wednesday": "水",
            "Thursday": "木",
            "Friday": "金",
            "Saturday": "土"
        ]
        
        return template.scheduledDays
            .compactMap { dayMap[$0] }
            .joined(separator: ", ")
    }
    private let luxuryColor = Color(red: 0.8, green: 0.7, blue: 0)
    @StateObject private var viewModel: TemplateDetailViewModel
    @Environment(\.presentationMode) var presentationMode
    
    init(template: WorkoutTemplate) {
        self.template = template
        _viewModel = StateObject(wrappedValue: TemplateDetailViewModel(template: template))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerBox
                
                CustomDivider()
                
                exercisesBox
            }
            .padding()
        }
        .background(.gray.opacity(0.1))
        .safeAreaInset(edge: .bottom) {
            bottomButtonBox
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

// MARK: views
extension TemplateDetailView {
    private var headerBox: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 8, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    if template.isPremium {
                        Text("プレミアム")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 12)
                            .background(luxuryColor)
                            .clipShape(.rect(cornerRadius: 6))
                    }
                    
                    Text(template.name)
                        .font(.title).bold()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            
            HStack(spacing: 0) {
                itemCell(
                    title: "曜日",
                    systemImage: "calendar",
                    value: localizedScheduledDays
                )
                itemCell(
                    title: "期間",
                    systemImage: "clock",
                    value: template.duration
                )
                itemCell(
                    title: "難易度",
                    systemImage: "chart.bar",
                    value: template.level
                )
            }
            .padding()
            .background(.main.opacity(0.1))
            .cornerRadius(8)
            
            if let notes = template.notes {
                Text(notes)
                    .foregroundStyle(.secondary)
                    .fontWeight(.semibold)
                    .padding(.leading)
            }
        }
    }
    
    private var exercisesBox: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                Image(systemName: "flame.fill")
                    .font(.title)
                
                VStack(alignment: .leading) {
                    Text("\(template.exercises.count)種目")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("エクササイズ")
                        .font(.headline)
                }
            }
            
            ForEach(Array(template.exercises.enumerated()), id: \.element.id) { index, exercise in
                WorkoutExerciseCell(workoutExercise: exercise)
                    .overlay(alignment: .topTrailing) {
                        Text("\(index + 1)")
                            .font(.largeTitle).bold()
                            .foregroundStyle(.secondary)
                            .padding()
                    }
            }
        }
    }
    
    @ViewBuilder
    private func itemCell(title: String, systemImage: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption)
            
            Text(value)
                .font(.headline)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var bottomButtonBox: some View {
        Button(action: {
            viewModel.addTemplateToUserWorkouts { success in
                if success {
                    // 성공 시 추가 작업이 필요하면 여기에 구현
                }
            }
        }) {
            VStack {
                if template.isPremium {
                    Text("プレミアム")
                        .font(.caption)
                        .foregroundStyle(.black)
                        .fontWeight(.semibold)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(
                            luxuryColor
                                .cornerRadius(4)
                        )
                }
                
                Text("このテンプレートを使う")
                    .font(.headline)
            }
        }
        .buttonStyle(CapsuleButtonStyle(color: .main))
        .disabled(viewModel.isLoading)
        .padding()
        .padding(.horizontal, 24)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    NavigationStack {
        TemplateDetailView(template: WorkoutTemplate.premiumMock)
    }
}
