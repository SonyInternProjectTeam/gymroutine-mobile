import SwiftUI

// 워크아웃 세션 모델 (결과 저장 및 표시에 사용)
struct WorkoutSessionModel {
    let workout: Workout // 원본 워크아웃 데이터
    let startTime: Date
    var elapsedTime: TimeInterval
    var completedSets: Set<String> = [] // 완료된 세트 정보 ("exerciseIndex-setIndex")
    // TODO: 필요에 따라 운동별 실제 수행 데이터 (무게, 횟수 등) 추가
}

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
    
    private init() {
        print("📱 AppWorkoutManager 초기화됨")
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
        let sessionViewModel = WorkoutSessionViewModel(workout: workout)
        self.workoutSessionViewModel = sessionViewModel
        self.currentWorkout = workout
        self.isWorkoutSessionActive = true
        self.isWorkoutSessionMaximized = true // 시작 시 전체 화면으로 표시
        self.showResultView = false // 결과 화면 숨김
        self.completedWorkoutSession = nil
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
        self.completedWorkoutSession = session
        self.showResultView = true // 결과 화면 표시 트리거

        // 기존 세션 상태 정리
        self.isWorkoutSessionActive = false
        self.isWorkoutSessionMaximized = false
        self.workoutSessionViewModel = nil
        self.currentWorkout = nil
         // 필요하다면 여기서 추가적인 정리 작업 수행
    }
    
    // 워크아웃 강제 종료 (사용자가 '종료' 버튼 탭 시)
    func endWorkout() {
        print("⏹️ AppWorkoutManager: 워크아웃 세션 강제 종료")
        // 모든 상태 초기화
        isWorkoutSessionActive = false
        isWorkoutSessionMaximized = false
        workoutSessionViewModel = nil
        currentWorkout = nil
        showResultView = false
        completedWorkoutSession = nil
         // TODO: 필요 시 사용자에게 종료 확인 알림 표시 로직 추가
    }

    // MARK: - Workout Result Handling
    // 워크아웃 결과 저장 (WorkoutResultView에서 호출됨)
    func saveWorkoutResult(session: WorkoutSessionModel?) {
        guard let session = session else {
            print("🔥 저장할 워크아웃 세션 데이터가 없습니다.")
            return
        }
        print("💾 AppWorkoutManager: 워크아웃 결과 저장 요청 - \(session.workout.name)")
        print("   - 시작 시간: \(session.startTime)")
        print("   - 소요 시간: \(session.elapsedTime)초")
        print("   - 완료 세트: \(session.completedSets.count)개")
        // TODO: 실제 데이터베이스 또는 로컬 저장소에 저장하는 로직 구현
        // 예: WorkoutRepository.shared.saveWorkoutResult(session)

        // 저장이 완료되면 결과 화면 닫기 (선택 사항, 버튼에서 직접 닫을 수도 있음)
        // dismissResultView()
    }

    // 결과 화면 닫기 (WorkoutResultView에서 호출됨)
    func dismissResultView() {
        print("🚪 AppWorkoutManager: 결과 화면 닫기")
        showResultView = false
        completedWorkoutSession = nil
    }
} 