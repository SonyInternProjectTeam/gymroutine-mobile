import SwiftUI
import FirebaseFirestore

struct CompletedWorkoutDetailView: View {
    let resultId: String
    @StateObject private var viewModel = CompletedWorkoutDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                workoutContentView
            }
            .padding(.bottom, 30)
        }
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
        VStack(alignment: .leading, spacing: 8) {
            // 헤더: 운동명과 완료 시각
            workoutHeaderView(result: result)
            
            Divider()
            
            // 운동 시간 정보
            if let duration = result.duration {
                durationView(duration: duration)
            }
            
            if let restTime = result.restTime {
                restTimeView(restTime: restTime)
            }            
            // 세트 수 정보
            if let exercises = result.exercises {
                totalSetsView(exercises: exercises)
            }
            
            Divider()
            
            // 운동 상세 정보
            exercisesListView(exercises: result.exercises)
            
            // 메모 섹션
            if let memo = result.memo, !memo.isEmpty {
                memoView(memo: memo)
            }
        }
    }
    
    // 운동명과 완료 시각 헤더 뷰
    @ViewBuilder
    private func workoutHeaderView(result: WorkoutResult) -> some View {
        Text(viewModel.workoutName ?? "不明なワークアウト")
            .font(.largeTitle)
            .fontWeight(.bold)
            .padding(.horizontal)
            .padding(.top)
        
        if let date = result.createdAt?.dateValue() {
            Text("完了日時: \(date.formatted(date: .long, time: .shortened))")
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }
    
    // 운동 시간 정보 뷰
    @ViewBuilder
    private func durationView(duration: Int) -> some View {
        HStack {
            Label("運動時間", systemImage: "clock")
                .font(.headline)
            Spacer()
            Text("\(duration / 60)分 \(duration % 60)秒")
                .font(.body)
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    @ViewBuilder
    private func restTimeView(restTime: Int) -> some View {
        HStack {
            Label("休憩時間", systemImage: "clock")
                .font(.headline)
            Spacer()
            Text("\(restTime / 60)分 \(restTime % 60)秒")
                .font(.body)
        }
        .padding(.horizontal)
        .padding(.top, 4)
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
            Text("エクササイズ")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 4)
            
            ForEach(exercises, id: \.id) { exercise in
                exerciseCard(exercise: exercise)
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
            Text("メモ")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 4)
            
            Text(memo)
                .font(.body)
                .padding(.horizontal)
                .padding(.bottom, 4)
        }
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    // 세트별 정보 행 뷰
    @ViewBuilder
    private func setRowView(index: Int, set: ExerciseSetResult) -> some View {
        HStack {
            Text("セット \(index + 1)")
                .font(.subheadline)
                .frame(width: 60, alignment: .leading)
            Text("\(String(format: "%.1f", set.weight ?? 0))kg")
                .font(.subheadline)
                .frame(width: 60, alignment: .center)
            Text("\(set.reps ?? 0)")
                .font(.subheadline)
                .frame(width: 60, alignment: .center)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(index % 2 == 0 ? Color(.systemBackground) : Color(.systemGray6))
    }
    
    // 운동 카드 뷰
    @ViewBuilder
    private func exerciseCard(exercise: ExerciseResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.exerciseName)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            if let sets = exercise.sets, !sets.isEmpty {
                VStack(spacing: 0) {
                    // 헤더
                    setsHeaderView
                    
                    // 세트 정보
                    ForEach(Array(sets.enumerated()), id: \.offset) { index, set in
                        setRowView(index: index, set: set)
                    }
                }
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.bottom, 8)
            } else {
                Text("セット情報なし")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    // 세트 헤더 뷰
    private var setsHeaderView: some View {
        HStack {
            Text("セット")
                .fontWeight(.semibold)
                .frame(width: 60, alignment: .leading)
            Text("重量")
                .fontWeight(.semibold)
                .frame(width: 60, alignment: .center)
            Text("回数")
                .fontWeight(.semibold)
                .frame(width: 60, alignment: .center)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray5))
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