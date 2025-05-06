import SwiftUI

struct WorkoutResultView: View {
    // AppWorkoutManager를 환경 객체로 받아옵니다.
    @EnvironmentObject var workoutManager: AppWorkoutManager
    // 표시할 워크아웃 세션 데이터입니다. 실제로는 완료된 세션 데이터를 받아와야 합니다.
    let workoutSession: WorkoutSessionModel // TODO: Pass the actual completed session data
    // 노트 입력을 위한 상태 변수
    @State private var notes: String

    private let totalSets: Int  //合計セット
    private let totalVolume: Double //総重量
    private let partCounts: [String: Int]   //partごとのセット数

    init(workoutSession: WorkoutSessionModel) {
        self.workoutSession = workoutSession
        _notes = State(initialValue: workoutSession.workout.notes ?? "")

        var setsCount = 0
        var volumeSum = 0.0
        var partCounter = [String: Int]()

        for exercise in workoutSession.workout.exercises {
            for set in exercise.sets {
                setsCount += 1
                volumeSum += (set.weight * Double(set.reps))
            }
        }
        
        for exercise in workoutSession.workout.exercises {
            partCounter[exercise.part, default: 0] += exercise.sets.count
        }

        self.partCounts = partCounter
        self.totalSets = setsCount
        self.totalVolume = volumeSum
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .center, spacing: 16) {
                    VStack() {
                        Spacer(minLength: 256)
                        
                        headerBox

                        flameTitleBox
                        
                        shareButtonBox.padding(.horizontal)
                    }
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.main, .clear]),
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )
                    
                    VStack(spacing: 24) {
                        CustomDivider()
                        
                        summaryBox
                        
                        CustomDivider()
                        
                        partSummaryBox
                        
                        CustomDivider()
                        
                        exerciseResultBox
                        
                        notesBox
                    }
                    .padding()
                }
                .offset(y: -256)
            }
            .vAlign(.top)
            .background(Color.gray.opacity(0.1))
            .scrollDismissesKeyboard(.immediately)
            
            bottomButtons
        }
        .edgesIgnoringSafeArea(.top)
    }

    // MARK: - Subviews
    private var headerBox: some View {
        Text("ワークアウト完了")
            .font(.largeTitle).bold()
            .foregroundStyle(.white)
            .shadow(radius: 2)
            .padding()
            .hAlign(.center)
            .padding(.top, 56)
    }
    
    private var flameTitleBox: some View {
        VStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .resizable()
                .scaledToFit()
                .frame(height: 180)
                .foregroundStyle(.red.gradient)
            
            VStack(spacing: 8) {
                Text("ワークアウト名")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                    .fontWeight(.semibold)
                
                
                Text(workoutSession.workout.name)
                    .font(.title.bold())
            }
        }
    }
    
    private var summaryBox: some View {
        VStack(spacing: 16) {
            totalSummaryBox
            
            workoutTimeSummaryBox
        }
    }
    
    private var totalSummaryBox: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                Label("総重量", systemImage: "figure.strengthtraining.traditional")
                    .font(.headline)
                
                HStack(alignment: .lastTextBaseline) {
                    Text("\(Int(totalVolume))")
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
                    Text("\(totalSets)")
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
    
    private var workoutTimeSummaryBox: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("時間", systemImage: "timer")
                .font(.headline)
            
            HStack(spacing: 0) {
                summaryCell(title: "合計", value: workoutSession.elapsedTime)
                summaryCell(title: "休憩", value: workoutSession.totalRestTime)
                summaryCell(title: "運動", value: workoutSession.elapsedTime - workoutSession.totalRestTime)
            }
        }
        .padding(12)
        .background()
        .clipShape(.rect(cornerRadius: 8))
        .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1.5)
    }
    
    @ViewBuilder
    private func summaryCell(title: String, value: Double) -> some View {
        VStack {
            Text(title)
                .font(.caption)
            
            Text(Int(value).formattedDuration)
                .font(.title2).bold()
        }
        .hAlign(.center)
    }
    
    private var partSummaryBox: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("鍛えた部位", systemImage: "dumbbell.fill")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(partCounts.sorted(by: { $0.value > $1.value }), id: \.key) { part, count in
                    let percentage = totalSets > 0 ? Double(count) / Double(totalSets) : 0
                    HStack {
                        Text(part.capitalized)
                            .font(.headline)
                            .frame(width: 56, alignment: .center)

                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(.systemGray4))
                                .frame(height: 24)
                                .cornerRadius(4)

                            // 塗りつぶしバー（percentageに応じた幅）
                            GeometryReader { geo in
                                Rectangle()
                                    .fill(.main.gradient)
                                    .frame(width: geo.size.width * percentage)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 24)
                        
                        Text("\(Int(percentage * 100))%")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .frame(width: 40, alignment: .center)
                    }
                }
            }
        }
    }
    
    private var shareButtonBox: some View {
        Button {
            shareWorkoutResult()
        } label: {
            Label("共有する", systemImage: "square.and.arrow.up")
                .font(.headline)
        }
        .buttonStyle(CapsuleButtonStyle(color: .main))
        .padding(.horizontal)
    }
    
    private var exerciseResultBox: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("エクササイズ", systemImage: "flame.fill")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(Array(workoutSession.workout.exercises.enumerated()), id: \.element.id) { exerciseIndex, workoutExercise in
                WorkoutExerciseCell(workoutExercise: workoutExercise)
                    .overlay(alignment: .topTrailing) {
                        Text("\(exerciseIndex + 1)")
                            .font(.largeTitle).bold()
                            .foregroundStyle(.secondary)
                            .padding()
                    }
            }
        }
    }
    
    private var notesBox: some View {
        VStack(alignment: .leading) {
            Text("メモ")
                .font(.headline)
            
            TextField(
                "メモを残す...",
                text: $notes,
                axis: .vertical
            )
            .submitLabel(.done)
            .frame(maxHeight: 248)
            .padding(12)
            .background(Color(UIColor.systemGray6))
            .clipShape(.rect(cornerRadius: 10))
            .clipped()
            .shadow(radius: 1)
        }
    }

    // 하단 버튼 (HStack으로 변경)
    private var bottomButtons: some View {
         VStack(spacing:0){ // 버튼 위 구분선
             Divider()
             HStack(spacing: 10) {
                 // 공유 버튼
                 Button {
                     workoutManager.dismissResultView()
                 } label: {
                     Text("閉じる")
                 }
                 .buttonStyle(SecondaryButtonStyle()) // 스타일 적용 (프로젝트에 정의된 스타일 사용 가정)

                 // 보존 버튼
                 Button {
                     saveWorkoutResultWithNotes()
                 } label: {
                     Label("保存する", systemImage: "tray.and.arrow.down")
                 }
                 .buttonStyle(PrimaryButtonStyle()) // 스타일 적용
             }
             .padding()
         }
        .background(Color(UIColor.systemGray6)) // 배경색 추가
    }
    
    // 노트 포함하여 결과 저장 요청
    private func saveWorkoutResultWithNotes() {
        print("Save button tapped with notes: \(notes)")
        // WorkoutSessionModel은 let이므로 직접 수정 불가.
        // AppWorkoutManager의 save 함수에서 노트를 받아 처리하도록 수정 필요.
        workoutManager.saveWorkoutResult(session: workoutSession, notes: notes) // 수정된 함수 호출 (다음 단계에서 AppWorkoutManager 수정 필요)
        // dismiss는 save 성공 후 AppWorkoutManager에서 처리
    }

    // 공유 기능 구현 (ActivityViewController 사용)
    private func shareWorkoutResult() {
        let shareText =
        """
        ワークアウト完了！
        総重量: \(Int(totalVolume))kg
        合計セット数: \(totalSets)
        合計時間: \(Int(workoutSession.elapsedTime).formattedDuration)
        """

        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)

        // 현재 활성화된 Scene의 window 찾기
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("🔥 공유 시트를 표시할 윈도우를 찾을 수 없습니다.")
            return
        }

        // iPad에서는 popover로 표시 설정
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = rootViewController.view
            popoverController.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        rootViewController.present(activityVC, animated: true)
    }
}

// MARK: - Preview Provider
struct WorkoutResultView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview용 샘플 데이터 - 실제 모델 타입 사용 (Workout, WorkoutExercise, ExerciseSet)
        // ExerciseModel은 WorkoutExercise 내부에 직접 포함되지 않음
        let sampleSets1 = [
            ExerciseSet(reps: 10, weight: 60), // isCompleted는 ExerciseSet에 없음
            ExerciseSet(reps: 8, weight: 65),
            ExerciseSet(reps: 6, weight: 70)
        ]
        // WorkoutExercise 생성 시 Exercise 정보 직접 전달 불필요 (name, part만 사용)
        let sampleWorkoutExercise1 = WorkoutExercise(name: "벤치 프레스", part: ExercisePart.chest.rawValue, key: "Bench Press", sets: sampleSets1)

        let sampleSets2 = [
            ExerciseSet(reps: 12, weight: 100),
            ExerciseSet(reps: 10, weight: 110)
        ]
        let sampleWorkoutExercise2 = WorkoutExercise(name: "스쿼트", part: ExercisePart.lowerbody.rawValue, key:"Squat", sets: sampleSets2)

        // Workout 모델 사용
        let sampleWorkout = Workout(
            userId: "previewUser",
            name: "샘플 워크아웃",
            createdAt: Date(),
            notes: "프리뷰용 설명", // 샘플 노트 추가
            isRoutine: false,
            scheduledDays: [],
            exercises: [sampleWorkoutExercise1, sampleWorkoutExercise2] // [WorkoutExercise] 전달
        )

        // 완료된 세트 정보
        let completedSetsData: Set<String> = ["0-0", "0-1", "1-0", "1-1"] // 벤치 2세트, 스쿼트 2세트 완료

        // WorkoutSessionModel 생성
        let sampleSession = WorkoutSessionModel(
            workout: sampleWorkout, // Workout 타입 전달
            startTime: Date().addingTimeInterval(-3665),
            elapsedTime: 3665,
            completedSets: completedSetsData
        )

        let manager = AppWorkoutManager.shared
        // manager.completedWorkoutSession = sampleSession // 결과 화면 테스트 시 주석 해제
        // manager.showResultView = true // 결과 화면 테스트 시 주석 해제

        return WorkoutResultView(workoutSession: sampleSession)
            .environmentObject(manager)
    }
}
