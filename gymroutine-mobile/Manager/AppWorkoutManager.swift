import SwiftUI
import FirebaseAuth // 사용자 ID 가져오기 위해 추가
import FirebaseFirestore // Timestamp 사용 위해 추가

@MainActor
class AppWorkoutManager: ObservableObject {
    static let shared = AppWorkoutManager()
    
    // MARK: - Active Session State
    @Published var isWorkoutSessionActive = false
    @Published var isWorkoutSessionMaximized = false // 모달/전체 화면 표시 여부
    @Published var currentWorkout: Workout? // 현재 진행 중인 워크아웃 원본
    @Published var workoutSessionViewModel: WorkoutSessionViewModel? // 현재 세션의 ViewModel

    // MARK: - Result View State
    @Published var showResultView = false // 결과 화면 표시 여부
    @Published var completedWorkoutSession: WorkoutSessionModel? = nil // 완료된 세션 데이터

    // MARK: - Session Persistence
    private let sessionPersistenceKey = "activeWorkoutSession"

    // MARK: - Compatibility Properties (삭제 예정 또는 유지)
    var isWorkoutInProgress: Bool { isWorkoutSessionActive }
    var showWorkoutSession: Bool {
        get { isWorkoutSessionActive && isWorkoutSessionMaximized }
        set {
            if newValue {
                isWorkoutSessionActive = true
                isWorkoutSessionMaximized = true
            } else {
                // Setting showWorkoutSession to false implies minimizing
                minimizeWorkoutSession()
            }
        }
    }
    var showMiniWorkoutSession: Bool {
        get { isWorkoutSessionActive && !isWorkoutSessionMaximized && !showResultView } // 결과 화면 표시 중에는 미니뷰 숨김
        // set은 직접 사용하지 않으므로 제거하거나 로직 검토
    }
    
    // Service 인스턴스 추가
    private let workoutService = WorkoutService()
    private let userManager = UserManager.shared
    private let groupService = GroupService() // GroupService 추가
    private let authService = AuthService() // AuthService 추가 (currentUser 접근용)
    
    private init() {
        print("📱 AppWorkoutManager 초기화됨")
        restoreWorkoutSession()
        // バックグラウンド移行時の通知を監視
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(saveWorkoutSessionStateToUserDefaults), // 이름 변경: saveWorkoutSessionStateToUserDefaults
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    // MARK: - Session
    // セッション状態をUserDefaultsに保存
    @objc private func saveWorkoutSessionStateToUserDefaults() { // 이름 변경 및 로직 분리
        guard let viewModel = workoutSessionViewModel else { return }

        let updatedWorkout = Workout(
            id: viewModel.workout.id ?? "",
            userId: viewModel.workout.userId,
            name: viewModel.workout.name,
            createdAt: viewModel.workout.createdAt,
            notes: viewModel.workout.notes,
            isRoutine: viewModel.workout.isRoutine,
            scheduledDays: viewModel.workout.scheduledDays,
            exercises: viewModel.exercisesManager.exercises
        )

        let session = WorkoutSessionModel(
            workout: updatedWorkout,
            startTime: viewModel.startTime,
            elapsedTime: Date().timeIntervalSince(viewModel.startTime),
            completedSets: viewModel.completedSets,
            totalRestTime: viewModel.getTotalRestTime()
        )

        do {
            let sessionData = session.encodeForUserDefaults()
            let jsonData = try JSONSerialization.data(withJSONObject: sessionData)
            let base64String = jsonData.base64EncodedString()
            UserDefaults.standard.set(base64String, forKey: sessionPersistenceKey)
            print("🔥 AppWorkoutManager: セッション状態をUserDefaultsに保存完了")
        } catch {
            print("🔥 AppWorkoutManager: セッション状態のUserDefaults保存に失敗: \\(error)")
        }
    }

    // 保存されたセッションを復元
    private func restoreWorkoutSession() {
        guard let base64String = UserDefaults.standard.string(forKey: sessionPersistenceKey),
              let jsonData = Data(base64Encoded: base64String),
              let sessionData = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let session = try? WorkoutSessionModel.decodeFromUserDefaults(sessionData) else {
            return
        }

        print("🔥 AppWorkoutManager: セッション状態を復元")

        // セッションを復元
        self.isWorkoutSessionActive = true
        self.currentWorkout = session.workout

        let viewModel = WorkoutSessionViewModel(workout: session.workout, startTime: session.startTime)
        viewModel.completedSets = session.completedSets
        self.workoutSessionViewModel = viewModel
    }

    // セッションをクリア
    func clearWorkoutSession() {
        print("🔥 AppWorkoutManager: セッション状態をクリア")
        UserDefaults.standard.removeObject(forKey: sessionPersistenceKey)
        self.isWorkoutSessionActive = false
        self.isWorkoutSessionMaximized = false
        self.currentWorkout = nil
        self.workoutSessionViewModel = nil
    }

    // MARK: - Workout Lifecycle
    // 워크아웃 시작
    func startWorkout(workout: Workout) {
        // 이미 진행 중인 세션이 있으면 종료 또는 경고 처리 (선택 사항)
        if isWorkoutSessionActive {
            print("⚠️ 이미 진행 중인 워크아웃이 있습니다. 새로운 워크아웃을 시작합니다.")
            endWorkout() // 기존 세션 종료
        }

        print("▶️ AppWorkoutManager: 워크아웃 시작 - \(workout.name)")
        // workoutId를 전달하여 WorkoutSessionViewModel 초기화
        guard let workoutId = workout.id else {
            print("🔥 워크아웃 ID가 없습니다.")
            return
        }
        let sessionViewModel = WorkoutSessionViewModel(workout: workout)
        self.workoutSessionViewModel = sessionViewModel
        self.currentWorkout = workout
        self.isWorkoutSessionActive = true
        self.isWorkoutSessionMaximized = true // 시작 시 전체 화면으로 표시
        self.showResultView = false // 결과 화면 숨김
        self.completedWorkoutSession = nil
        
        // 워크아웃 세션 시작 (이제 init에서 처리됨)
        // sessionViewModel.startFromBeginning()

        // 사용자 isActive 상태를 true로 업데이트
        Task {
            let result = await userManager.updateUserActiveStatus(isActive: true)
            if case .failure(let error) = result {
                print("⚠️ 사용자 isActive 상태 업데이트 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // 워크아웃 세션 최소화 (모달 닫기)
    func minimizeWorkoutSession() {
        if isWorkoutSessionActive {
            isWorkoutSessionMaximized = false
            print("🔽 AppWorkoutManager: 워크아웃 세션 최소화")
        }
    }
    
    // 최소화된 워크아웃 세션 최대화 (미니뷰 탭 시)
    func maximizeWorkoutSession() {
        if isWorkoutSessionActive {
            isWorkoutSessionMaximized = true
            print("🔼 AppWorkoutManager: 워크아웃 세션 최대화")
        }
    }
    
    // 워크아웃 완료 처리 (WorkoutSessionViewModel에서 호출됨)
    func completeWorkout(session: WorkoutSessionModel) {
        print("✅ AppWorkoutManager: 워크아웃 완료됨 - \(session.workout.name)")
        // 상태 변경 전 로그 추가
        print("   ➡️ Setting completedWorkoutSession and showResultView = true")
        self.completedWorkoutSession = session
        self.showResultView = true // 결과 화면 표시 트리거
        // 상태 변경 후 로그 추가
        print("   ⏸️ Current State: showResultView = \(self.showResultView), completedWorkoutSession is \(self.completedWorkoutSession == nil ? "nil" : "set")")

        // 기존 세션 상태 정리
        print("   🧹 Clearing active session states (isWorkoutSessionActive = false, isWorkoutSessionMaximized = false)")
        clearWorkoutSession()
        
        // 사용자 isActive 상태를 false로 업데이트
        Task {
            let result = await userManager.updateUserActiveStatus(isActive: false)
            if case .failure(let error) = result {
                print("⚠️ 사용자 isActive 상태 업데이트 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // 워크아웃 강제 종료 (사용자가 '종료' 버튼 탭 시)
    func endWorkout() {
        print("⏹️ AppWorkoutManager: 워크아웃 세션 강제 종료")
        // 모든 상태 초기화
        clearWorkoutSession()
        showResultView = false
        completedWorkoutSession = nil
        
        // 사용자 isActive 상태를 false로 업데이트
        Task {
            let result = await userManager.updateUserActiveStatus(isActive: false)
            if case .failure(let error) = result {
                print("⚠️ 사용자 isActive 상태 업데이트 실패: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Workout Result Handling
    // 워크아웃 결과 저장 (WorkoutResultView에서 호출됨)
    func saveWorkoutResult(session: WorkoutSessionModel?, notes: String) {
        guard let session = session else {
            print("🔥 저장할 워크아웃 세션 데이터가 없습니다.")
            return
        }
        guard let userId = authService.getCurrentUser()?.uid else { // authService 사용
            print("🔥 사용자 ID를 가져올 수 없습니다. 로그인이 필요합니다.")
            return
        }
        
        print("💾 AppWorkoutManager: 워크아웃 결과 저장 요청 - \\(session.workout.name)")
        print("   - 노트: \\(notes)")
        
        // WorkoutSessionModel -> WorkoutResultModel 변환
        let now = Date()
        let exercisesResult: [ExerciseResultModel] = session.workout.exercises.enumerated().compactMap { exerciseIndex, workoutExercise in
            let setsResult: [SetResultModel] = workoutExercise.sets.map { setInfo in
                return SetResultModel(Reps: setInfo.reps, Weight: setInfo.weight)
            }
            
            let completedSetsCount = workoutExercise.sets.indices.filter { setIndex in
                session.completedSets.contains("\\(exerciseIndex)-\\(setIndex)")
            }.count
            
            return ExerciseResultModel(exerciseName: workoutExercise.name,
                                       key: workoutExercise.key ?? workoutExercise.name,
                                       setsCompleted: completedSetsCount,
                                       sets: setsResult)
        }
        
        let workoutResult = WorkoutResultModel(
            duration: Int(session.elapsedTime),
            restTime: Int(session.totalRestTime),
            workoutID: session.workout.id,
            exercises: exercisesResult,
            notes: notes.isEmpty ? nil : notes,
            createdAt: Timestamp(date: now)
        )
        
        // WorkoutService를 사용하여 Firestore에 저장
        Task {
            UIApplication.showLoading()
            let saveTaskResult = await workoutService.saveWorkoutResult(userId: userId, result: workoutResult)
            
            // 저장 완료 후에 isActive 상태를 false로 업데이트 (이미 false여도 한번 더 확인)
            let activeResult = await userManager.updateUserActiveStatus(isActive: false)
            if case .failure(let error) = activeResult {
                print("⚠️ 사용자 isActive 상태 업데이트 실패: \\(error.localizedDescription)")
            }
            
            UIApplication.hideLoading()
            
            switch saveTaskResult {
            case .success():
                print("✅ AppWorkoutManager: 워크아웃 결과 저장 완료")
                // 그룹 목표 업데이트 로직 호출
                await self.updateGroupGoalsAfterWorkout(userId: userId, completedWorkoutSession: session)
                
                await MainActor.run {
                    dismissResultView()
                    UIApplication.showBanner(type: .success, message: "ワークアウト結果を保存しました")
                }
            case .failure(let error):
                print("🔥 AppWorkoutManager: 워크아웃 결과 저장 실패: \\(error.localizedDescription)")
                UIApplication.showBanner(type: .error, message: "ワークアウト結果の保存に失敗しました")
            }
        }
    }

    // 결과 화면 닫기 (WorkoutResultView에서 호출됨)
    func dismissResultView() {
        print("🚪 AppWorkoutManager: 결과 화면 닫기")
        showResultView = false
        completedWorkoutSession = nil
    }
    
    // MARK: - Group Goal Update Helper
    
    private func updateGroupGoalsAfterWorkout(userId: String, completedWorkoutSession: WorkoutSessionModel) async {
        print("🔄 [AppWorkoutManager] 워크아웃 완료 후 그룹 목표 업데이트 시작. 사용자: \(userId)")
        
        // 1. 사용자가 속한 그룹 목록 가져오기
        let userGroupsResult = await groupService.getUserGroups(userId: userId)
        guard case .success(let userGroups) = userGroupsResult, !userGroups.isEmpty else {
            if case .failure(let error) = userGroupsResult {
                print("⛔️ [AppWorkoutManager] 사용자 그룹 목록 가져오기 실패: \(error.localizedDescription)")
            } else {
                print("ℹ️ [AppWorkoutManager] 사용자가 속한 그룹이 없습니다. 목표 업데이트를 건너<0xEB><0x9A><0xB5>니다.")
            }
            return
        }
        
        print("ℹ️ [AppWorkoutManager] 사용자(\(userId))가 속한 그룹 수: \(userGroups.count)")
        
        let today = Date()
        
        // 운동 세션에서 필요한 값 미리 계산
        let workoutDurationMinutes = completedWorkoutSession.elapsedTime / 60.0 // 초를 분으로 변환
        var totalWeightLifted: Double = 0
        for exercise in completedWorkoutSession.workout.exercises {
            for set in exercise.sets {
                // 해당 세트가 완료되었는지 확인 (completedWorkoutSession.completedSets 사용)
                // completedSets의 문자열 형식 ("exerciseIndex-setIndex")을 확인하고 해당 로직 추가 필요
                // 여기서는 모든 세트가 기여한다고 가정하거나, WorkoutResultModel 생성 시 사용된 completedSetsCount 로직을 참고하여 필터링 필요
                // 지금은 단순화를 위해 모든 세트의 무게를 합산합니다. 실제 구현 시 completedSets를 정확히 반영해야 합니다.
                totalWeightLifted += set.weight * Double(set.reps)
            }
        }
        print("ℹ️ [AppWorkoutManager] 이번 워크아웃 정보: 운동시간 \(String(format: "%.2f", workoutDurationMinutes))분, 총 들어올린 무게 \(totalWeightLifted)kg")

        for group in userGroups {
            guard let groupId = group.id else {
                print("⚠️ [AppWorkoutManager] 그룹 ID가 없는 그룹(\(group.name))은 건너<0xEB><0x9A><0xB5>니다.")
                continue
            }
            
            let groupGoalsResult = await groupService.getGroupGoals(groupId: groupId)
            guard case .success(let groupGoals) = groupGoalsResult, !groupGoals.isEmpty else {
                if case .failure(let error) = groupGoalsResult {
                    print("⛔️ [AppWorkoutManager] 그룹(\(group.name)) 목표 가져오기 실패: \(error.localizedDescription)")
                } else {
                    print("ℹ️ [AppWorkoutManager] 그룹(\(group.name))에 활성 목표가 없습니다.")
                }
                continue
            }
            
            print("ℹ️ [AppWorkoutManager] 그룹 '\(group.name)'의 목표 수: \(groupGoals.count)")
            
            for goal in groupGoals {
                guard let goalId = goal.id else {
                    print("⚠️ [AppWorkoutManager] 목표 ID가 없는 목표(\(goal.title))는 건너<0xEB><0x9A><0xB5>니다.")
                    continue
                }
                
                if goal.isActive && today >= goal.startDate && today <= goal.endDate {
                    var progressToAdd: Double = 0
                    var logMessageSuffix = ""

                    switch goal.goalType {
                    case .workoutCount:
                        progressToAdd = 1.0
                        logMessageSuffix = "운동 횟수 목표"
                    case .workoutDuration:
                        progressToAdd = workoutDurationMinutes
                        logMessageSuffix = "운동 시간 목표 (분)"
                    case .weightLifted:
                        progressToAdd = totalWeightLifted
                        logMessageSuffix = "총 들어올린 무게 목표 (kg)"
                    // default: // 다른 목표 유형은 여기서 처리하지 않음
                    //     print("ℹ️ [AppWorkoutManager] 그룹 '\(group.name)'의 목표 '\(goal.title)' (유형: \(goal.goalType))는 자동 업데이트 대상 아님.")
                    //     continue
                    }

                    if progressToAdd > 0 {
                        print("🎯 [AppWorkoutManager] 그룹 '\(group.name)'의 목표 '\(goal.title)' (\(logMessageSuffix)) 업데이트 대상입니다.")
                        
                        let currentProgress = goal.currentProgress[userId] ?? 0
                        let newProgress = currentProgress + progressToAdd
                        
                        // 목표 진행률이 목표치를 초과하지 않도록, 혹은 초과해도 업데이트 (정책에 따라 다름 - 여기서는 초과 허용)
                        // 만약 newProgress > goal.targetValue일 때 goal.targetValue로 제한하려면 아래와 같이 수정:
                        // let finalProgress = min(newProgress, goal.targetValue)
                        let finalProgress = newProgress // 현재는 초과 허용

                        if finalProgress > currentProgress { // 실제로 진행률이 증가하는 경우에만 업데이트
                             print("📈 [AppWorkoutManager] 목표 '\(goal.title)' 진행률 업데이트 시도: \(String(format: "%.2f", currentProgress)) -> \(String(format: "%.2f", finalProgress)) / \(goal.targetValue) \(goal.unit)")
                            let updateResult = await groupService.updateGroupGoalProgress(groupId: groupId, goalId: goalId, progress: finalProgress)
                            
                            switch updateResult {
                            case .success:
                                print("✅ [AppWorkoutManager] 그룹 '\(group.name)' 목표 '\(goal.title)' 진행률 업데이트 성공.")
                            case .failure(let error):
                                print("⛔️ [AppWorkoutManager] 그룹 '\(group.name)' 목표 '\(goal.title)' 진행률 업데이트 실패: \(error.localizedDescription)")
                            }
                        } else if finalProgress == currentProgress && progressToAdd > 0 {
                            print("🤔 [AppWorkoutManager] 목표 '\(goal.title)'는 이미 최대치이거나 업데이트로 변경사항 없음 (현재: \(currentProgress), 추가: \(progressToAdd), 목표: \(goal.targetValue)).")
                        }
                    } else {
                        print("ℹ️ [AppWorkoutManager] 그룹 '\(group.name)'의 목표 '\(goal.title)' (유형: \(goal.goalType))는 이번 운동으로 추가될 진행상황이 없습니다.")
                    }
                } else {
                     print("🚫 [AppWorkoutManager] 그룹 '\(group.name)'의 목표 '\(goal.title)'는 업데이트 대상이 아님 (활성: \(goal.isActive), 기간: \(goal.startDate) - \(goal.endDate)).")
                }
            }
        }
        print("🏁 [AppWorkoutManager] 모든 그룹 목표 업데이트 처리 완료.")
    }
} 
