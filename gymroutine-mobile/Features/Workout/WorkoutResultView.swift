import SwiftUI

struct WorkoutResultView: View {
    // AppWorkoutManager를 환경 객체로 받아옵니다.
    @EnvironmentObject var workoutManager: AppWorkoutManager
    // 표시할 워크아웃 세션 데이터입니다. 실제로는 완료된 세션 데이터를 받아와야 합니다.
    let workoutSession: WorkoutSessionModel // TODO: Pass the actual completed session data
    // 노트 입력을 위한 상태 변수
    @State private var notes: String
    private let analyticsService = AnalyticsService.shared

    // 초기화 시 workoutSession의 노트를 @State 변수에 할당
    init(workoutSession: WorkoutSessionModel) {
        self.workoutSession = workoutSession
        // workoutSession.workout.notes가 nil이면 빈 문자열로 초기화
        _notes = State(initialValue: workoutSession.workout.notes ?? "")
    }

    var body: some View {
        NavigationView { // 결과 화면 내에서 네비게이션이 필요할 수 있으므로 추가
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Workout Completed!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.bottom)

                        // 요약 섹션
                        workoutSummarySection

                        // 운동 상세 섹션
                        exerciseDetailsSection

                        // 노트 섹션 추가
                        notesSection

                        Spacer() // 콘텐츠를 위로 밀기
                    }
                    .padding() // ScrollView 콘텐츠 패딩
                }
                
                // 하단 버튼 영역
                bottomButtons
            }
            .navigationTitle("Workout Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        workoutManager.dismissResultView()
                        
                        // Log dismiss result view
                        analyticsService.logUserAction(
                            action: "dismiss_workout_result",
                            itemId: workoutSession.workout.id,
                            contentType: "workout_result"
                        )
                    }
                }
            }
            .onAppear {
                // Log screen view
                analyticsService.logScreenView(screenName: "WorkoutResult")
                
                // Log workout result viewed
                analyticsService.logEvent("workout_result_viewed", parameters: [
                    "workout_id": workoutSession.workout.id,
                    "workout_name": workoutSession.workout.name,
                    "elapsed_time": workoutSession.elapsedTime,
                    "total_rest_time": workoutSession.totalRestTime,
                    "active_time": workoutSession.elapsedTime - workoutSession.totalRestTime,
                    "exercise_count": workoutSession.workout.exercises.count
                ])
            }
        }
    }

    // MARK: - Subviews
    
    // 워크아웃 요약 섹션
    private var workoutSummarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Summary")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Workout Name: \(workoutSession.workout.name)")
            Text("Total Time: \(formattedTotalTime(workoutSession.elapsedTime))")
            Text("Rest Time: \(formattedTotalTime(workoutSession.totalRestTime))")
            Text("Active Time: \(formattedTotalTime(workoutSession.elapsedTime - workoutSession.totalRestTime))")
            // TODO: 총 볼륨 등 추가 요약 정보 표시
            // let totalVolume = calculateTotalVolume()
            // Text("Total Volume: \(String(format: "%.1f", totalVolume)) kg")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // 운동 상세 정보 섹션
    private var exerciseDetailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Exercises")
                .font(.title2)
                .fontWeight(.semibold)

            // 운동 목록
            // Workout 모델의 exercises는 [WorkoutExercise] 타입입니다.
            ForEach(Array(workoutSession.workout.exercises.enumerated()), id: \.element.id) { exerciseIndex, workoutExercise in
                VStack(alignment: .leading, spacing: 8) {
                    // 운동 이름 표시 (WorkoutExercise 구조체 사용)
                    Text(workoutExercise.name).fontWeight(.medium)
                    
                    // 세트 정보 표시 (WorkoutExercise의 sets는 [ExerciseSet] 타입)
                    ForEach(Array(workoutExercise.sets.enumerated()), id: \.offset) { setIndex, setInfo in
                        setRow(exerciseIndex: exerciseIndex, setIndex: setIndex, setInfo: setInfo)
                    }
                }
                .padding(.bottom, 10)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // 각 세트 정보 행 (ExerciseSet 구조체 사용)
    private func setRow(exerciseIndex: Int, setIndex: Int, setInfo: ExerciseSet) -> some View {
        let isCompleted = workoutSession.completedSets.contains("\(exerciseIndex)-\(setIndex)")
        
        return HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .gray)
                .frame(width: 20)
            
            Text("Set \(setIndex + 1):")
                .font(.callout)
                .frame(width: 60, alignment: .leading)
            
            // ExerciseSet의 reps, weight 사용
            Text("\(String(format: "%.1f", setInfo.weight)) kg x \(setInfo.reps) reps")
                .font(.callout)
            
            Spacer()
        }
        .opacity(isCompleted ? 1.0 : 0.7)
    }
    
    // 노트 섹션
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notes")
                .font(.title2)
                .fontWeight(.semibold)

            TextEditor(text: $notes)
                .frame(height: 100) // 적절한 높이 지정
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .submitLabel(.done) // 키보드 완료 버튼
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    // 하단 버튼 (HStack으로 변경)
    private var bottomButtons: some View {
         VStack(spacing:0){ // 버튼 위 구분선
             Divider()
             HStack(spacing: 10) {
                 // 공유 버튼
                 Button {
                     shareWorkoutResult()
                     
                     // Log share workout result
                     analyticsService.logUserAction(
                         action: "share_workout_result",
                         itemId: workoutSession.workout.id,
                         itemName: workoutSession.workout.name,
                         contentType: "workout_result"
                     )
                 } label: {
                     Label("共有", systemImage: "square.and.arrow.up")
                 }
                 .buttonStyle(SecondaryButtonStyle()) // 스타일 적용 (프로젝트에 정의된 스타일 사용 가정)

                 // 보존 버튼
                 Button {
                     saveWorkoutResultWithNotes()
                     
                     // Log save workout result
                     analyticsService.logUserAction(
                         action: "save_workout_result",
                         itemId: workoutSession.workout.id,
                         itemName: workoutSession.workout.name,
                         contentType: "workout_result"
                     )
                 } label: {
                     Label("保存", systemImage: "tray.and.arrow.down") // 아이콘 변경 제안
                 }
                 .buttonStyle(PrimaryButtonStyle()) // 스타일 적용
             }
             .padding()
         }
        .background(Color(UIColor.systemGray6)) // 배경색 추가
    }

    // MARK: - Helper Functions

    private func formattedTotalTime(_ time: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: time) ?? "0s"
    }

    // TODO: 총 볼륨 계산 로직 (필요 시)
    // private func calculateTotalVolume() -> Double {
    //     var totalVolume: Double = 0
    //     for (exerciseIndex, exercise) in workoutSession.workout.exercises.enumerated() {
    //         for (setIndex, setInfo) in exercise.sets.enumerated() {
    //             if workoutSession.completedSets.contains("\(exerciseIndex)-\(setIndex)") {
    //                 totalVolume += Double(setInfo.reps) * setInfo.weight
    //             }
    //         }
    //     }
    //     return totalVolume
    // }

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
        // 공유할 내용 생성 (텍스트, 이미지 등)
        let shareText = """
        Workout Completed!
        Name: \(workoutSession.workout.name)
        Time: \(formattedTotalTime(workoutSession.elapsedTime))
        \(notes.isEmpty ? "" : "\nNotes: \(notes)")
        """
        // TODO: 운동 상세 정보나 스크린샷 등 추가 가능

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
        let sampleWorkoutExercise1 = WorkoutExercise(name: "벤치 프레스", part: ExercisePart.chest.rawValue, sets: sampleSets1)

        let sampleSets2 = [
            ExerciseSet(reps: 12, weight: 100),
            ExerciseSet(reps: 10, weight: 110)
        ]
        let sampleWorkoutExercise2 = WorkoutExercise(name: "스쿼트", part: ExercisePart.legs.rawValue, sets: sampleSets2)

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

// MARK: - Preview Provider

// WorkoutModel, WorkoutExerciseDetail, ExerciseModel, WorkoutSet 정의가 포함된
// Models/WorkoutModel.swift 또는 유사한 파일을 임포트해야 할 수 있습니다.
// import Models // <- 실제 파일 구조에 맞게 수정
