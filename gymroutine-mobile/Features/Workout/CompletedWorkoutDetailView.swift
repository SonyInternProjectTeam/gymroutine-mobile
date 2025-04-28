




import SwiftUI
import FirebaseFirestore

struct CompletedWorkoutDetailView: View {
    let resultId: String
    @StateObject private var viewModel = CompletedWorkoutDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            workoutContentView
                .padding()
        }
        
        .background(Color.gray.opacity(0.1))
        .navigationTitle("ワークアウト結果")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadWorkoutResult(resultId: resultId)
        }
    }
    
    // 결과 데이터에 따른 메인 콘텐츠 뷰
    private var workoutContentView: some View {
        Group {
            if let result = viewModel.workoutResult {
                workoutDetailView(result: result)
            } else if viewModel.isLoading {
                loadingView
            } else {
                errorView
            }
        }
    }
    
    // 로딩 중일 때 표시하는 뷰
    private var loadingView: some View {
        ProgressView()
            .padding()
            .frame(maxWidth: .infinity)
    }
    
    // 오류 발생 시 표시하는 뷰
    private var errorView: some View {
        Text("結果の詳細を読み込めませんでした")
            .foregroundColor(.secondary)
            .padding()
            .frame(maxWidth: .infinity)
    }
    
    // 운동 결과 상세 정보 뷰
    @ViewBuilder
    private func workoutDetailView(result: WorkoutResult) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // 헤더: 운동명과 완료 시각
            workoutHeaderView(result: result)
            
            CustomDivider()
            
            HStack(spacing: 16) {
                
                if let duration = result.duration {
                    timeCell(title: "運動時間", value: duration)
                }
                
                if let restTime = result.restTime {
                    timeCell(title: "休憩時間", value: restTime)
                }
            }
            // 세트 수 정보
            if let exercises = result.exercises {
                totalSetsView(exercises: exercises)
            }
            
            CustomDivider()
            
            // 운동 상세 정보
            exercisesListView(exercises: result.exercises)
            
            // 메모 섹션
            if let memo = result.memo, !memo.isEmpty {
                CustomDivider()
                
                memoView(memo: memo)
            }
        }
    }
    
    // 운동명과 완료 시각 헤더 뷰
    @ViewBuilder
    private func workoutHeaderView(result: WorkoutResult) -> some View {
        VStack(alignment: .leading) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray)
                    .frame(width: 8)
                
                Text(viewModel.workoutName ?? "不明なワークアウト")
                    .font(.title).bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.1)
            }
            
            if let date = result.createdAt?.dateValue() {
                Text("完了日時: \(date.formatted(date: .long, time: .shortened))")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private func timeCell(title: String, value: Int) -> some View {
        VStack(spacing: 16) {
            Text(title)
                .foregroundStyle(.secondary)
                .font(.caption)
                .hAlign(.leading)
            
            Text("\(value / 60)分 \(value % 60)秒")
                .font(.title2.bold())
                .hAlign(.center)
        }
        .padding(12)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1.5)
    }
    
    // 총 세트 수 정보 뷰
    @ViewBuilder
    private func totalSetsView(exercises: [ExerciseResult]) -> some View {
        let totalSets = exercises.reduce(0) { $0 + ($1.sets?.count ?? 0) }
        
        HStack {
            Label("総セット数", systemImage: "number.square")
                .font(.headline)
            Spacer()
            Text("\(totalSets)セット")
                .font(.body)
        }
        .padding(.horizontal)
        .padding(.top, 2)
    }
    
    // 운동 목록 표시 뷰
    @ViewBuilder
    private func exercisesListView(exercises: [ExerciseResult]?) -> some View {
        if let exercises = exercises, !exercises.isEmpty {
            Label("エクササイズ", systemImage: "flame.fill")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(exercises.indices, id: \.self) { index in
                let exercise = exercises[index]
                
                ExerciseResultCell(
                    exerciseIndex: index + 1,
                    exercise: ExerciseResultModel(
                        exerciseName: exercise.exerciseName,
                        setsCompleted: exercise.setsCompleted ?? 0,
                        sets: exercise.sets?.map { set in
                            SetResultModel(
                                Reps: set.reps ?? 0,
                                Weight: set.weight
                            )
                        } ?? []
                    )
                )
            }
        } else {
            Text("エクササイズ情報がありません")
                .foregroundColor(.secondary)
                .padding()
        }
    }
    
    // 메모 표시 뷰
    @ViewBuilder
    private func memoView(memo: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("ノート", systemImage: "note.text")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(memo)
                .font(.subheadline)
                .padding(.horizontal, 4)
        }
    }
}

class CompletedWorkoutDetailViewModel: ObservableObject {
    @Published var workoutResult: WorkoutResult?
    @Published var workoutName: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let resultService = ResultService()
    private let workoutService = WorkoutService()
    
    func loadWorkoutResult(resultId: String) {
        isLoading = true
        
        Task {
            let result = await resultService.fetchWorkoutResultDetail(resultId: resultId)
            
            // 워크아웃 결과를 가져온 후, 해당 워크아웃 ID가 있다면 워크아웃 이름도 가져옴
            if let result = result, let workoutId = result.workoutId {
                do {
                    let workout = try await workoutService.fetchWorkoutById(workoutID: workoutId)
                    
                    DispatchQueue.main.async {
                        self.workoutName = workout.name
                        self.workoutResult = result
                        self.isLoading = false
                    }
                } catch {
                    print("[ERROR] ワークアウト情報の取得に失敗: \(error.localizedDescription)")
                    
                    DispatchQueue.main.async {
                        self.workoutResult = result
                        self.isLoading = false
                        
                        // ワークアウト名がない場合はエクササイズ名を使用
                        if let firstExercise = result.exercises?.first {
                            self.workoutName = firstExercise.exerciseName + "のワークアウト"
                        } else {
                            self.workoutName = "Quick Start"
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.workoutResult = result
                    self.isLoading = false
                    
                    if result == nil {
                        self.errorMessage = "ワークアウト結果の読み込みに失敗しました"
                    } else if let exercises = result?.exercises, !exercises.isEmpty {
                        // ワークアウトIDがなく、エクササイズがある場合
                        self.workoutName = exercises[0].exerciseName + "のワークアウト"
                    } else {
                        self.workoutName = "Quick Start"
                    }
                }
            }
        }
    }
}

struct CompletedWorkoutDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CompletedWorkoutDetailView(resultId: "sample-id")
        }
    }
} 
