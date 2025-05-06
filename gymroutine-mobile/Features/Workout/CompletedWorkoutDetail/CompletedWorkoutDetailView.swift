




import SwiftUI
import FirebaseFirestore

struct CompletedWorkoutDetailView: View {
    let resultId: String
    @StateObject private var viewModel = CompletedWorkoutDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Group {
            if let result = viewModel.workoutResult {
                workoutDetailView(result: result)
            } else if viewModel.isLoading {
                loadingView
            } else {
                errorView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
        .navigationTitle("ワークアウト結果")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadWorkoutResult(resultId: resultId)
        }
    }
    
    // 로딩 중일 때 표시하는 뷰
    private var loadingView: some View {
        ProgressView()
            .padding()
    }
    
    // 오류 발생 시 표시하는 뷰
    private var errorView: some View {
        Text("結果の詳細を読み込めませんでした。")
            .font(.headline)
            .foregroundColor(.secondary)
            .padding()
    }
    
    // 운동 결과 상세 정보 뷰
    @ViewBuilder
    private func workoutDetailView(result: WorkoutResult) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 헤더: 운동명과 완료 시각
                workoutHeaderView(result: result)
                
                CustomDivider()
                
                summaryView(result: result)
                
                CustomDivider()
                
                // 운동 상세 정보
                exercisesListView(exercises: result.exercises)
                
                // 메모 섹션
                if let memo = result.memo, !memo.isEmpty {
                    CustomDivider()
                    
                    memoView(memo: memo)
                }
            }
            .padding()
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
    private func summaryView(result: WorkoutResult) -> some View {
        VStack(spacing: 16) {
            totalSummaryBox
            
            workoutTimeSummayBox(result: result)
        }
    }
    
    private var totalSummaryBox: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                Label("総重量", systemImage: "figure.strengthtraining.traditional")
                    .font(.headline)
                
                HStack(alignment: .lastTextBaseline) {
                    Text("\(Int(viewModel.totalVolume))")
                        .font(.largeTitle).bold()
                        .foregroundStyle(.main)
                        .lineLimit(1)
                        .minimumScaleFactor(0.1)
                    Text("kg")
                        .fontWeight(.semibold)
                }
                .hAlign(.center)
            }
            .padding()
            .background()
            .clipShape(.rect(cornerRadius: 8))
            .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1.5)
            
            VStack(alignment: .leading, spacing: 16) {
                Label("合計セット数", systemImage: "list.number.rtl")
                    .font(.headline)
                
                HStack(alignment: .lastTextBaseline) {
                    Text("\(viewModel.totalSets)")
                        .font(.largeTitle).bold()
                        .foregroundStyle(.main)
                    Text("回")
                        .fontWeight(.semibold)
                }
                .hAlign(.center)
            }
            .padding()
            .background()
            .clipShape(.rect(cornerRadius: 8))
            .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1.5)
        }
    }
    
    @ViewBuilder
    private func workoutTimeSummayBox(result: WorkoutResult) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                Label("運動時間", systemImage: "figure.run")
                    .font(.headline)
                
                Group {
                    if let duration = result.duration {
                        Text(viewModel.formattedTime(from: duration))
                    } else { Text("--") }
                }
                .font(.title2).bold()
                .foregroundStyle(.main)
                .hAlign(.center)
            }
            .padding()
            .background()
            .clipShape(.rect(cornerRadius: 8))
            .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1.5)
            
            VStack(alignment: .leading, spacing: 16) {
                Label("休憩時間", systemImage: "cup.and.saucer")
                    .font(.headline)
                
                Group {
                    if let restTime = result.restTime {
                        Text(viewModel.formattedTime(from: restTime))
                    } else { Text("--") }
                }
                .font(.title2).bold()
                .foregroundStyle(.main)
                .hAlign(.center)
            }
            .padding()
            .background()
            .clipShape(.rect(cornerRadius: 8))
            .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1.5)
        }
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
                        key: exercise.key,
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

struct CompletedWorkoutDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CompletedWorkoutDetailView(resultId: "sample-id")
        }
    }
} 
