import SwiftUI

struct WorkoutResultView: View {
    // AppWorkoutManager를 환경 객체로 받아옵니다.
    @EnvironmentObject var workoutManager: AppWorkoutManager
    // 표시할 워크아웃 세션 데이터입니다. 실제로는 완료된 세션 데이터를 받아와야 합니다.
    let workoutSession: WorkoutSessionModel // TODO: Pass the actual completed session data

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

                        Spacer() // 콘텐츠를 위로 밀기
                    }
                    .padding() // ScrollView 콘텐츠 패딩
                }
                
                // 하단 저장 버튼
                saveButton
            }
            .navigationTitle("Workout Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        workoutManager.dismissResultView()
                    }
                }
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
    
    // 하단 저장 버튼
    private var saveButton: some View {
        Button {
            print("Save button tapped!")
            workoutManager.saveWorkoutResult(session: workoutSession)
            workoutManager.dismissResultView()
        } label: {
            Text("보존")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
        }
        .padding(.horizontal)
        .padding(.bottom)
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
            notes: "프리뷰용 설명",
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
