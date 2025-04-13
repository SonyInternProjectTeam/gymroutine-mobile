//
//  WorkoutSessionViewModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/04/03.
//

import SwiftUI
import AVFoundation

@MainActor
final class WorkoutSessionViewModel: ObservableObject {
    // MARK: - Properties
    @Published var workout: Workout
    @Published var exercises: [WorkoutExercise]
    @Published var minutes: Int = 0
    @Published var seconds: Int = 0
    @Published var currentExerciseIndex: Int = 0
    @Published var completedSets: Set<String> = []  // "exerciseIndex-setIndex" 형식으로 저장
    @Published var isDetailView: Bool = true  // true: 상세 화면, false: 리스트 화면
    @Published var currentSetIndex: Int = 0  // 현재 운동의 현재 세트 인덱스
    @Published var showCompletionAlert: Bool = false // 워크아웃 완료 확인 알림 표시 여부
    
    // 휴식 타이머 관련 속성
    @Published var isRestTimerActive = false
    @Published var restSeconds = 90  // 기본 휴식 시간 90초
    @Published var remainingRestSeconds = 90
    private var restTimer: Timer?
    private var player: AVAudioPlayer?
    
    private var timer: Timer?
    private var startTime: Date
    
    // MARK: - Initialization
    init(workout: Workout) {
        print("📱 WorkoutSessionViewModel 초기화됨")
        print("📱 전달받은 워크아웃: \(workout.name), 운동 개수: \(workout.exercises.count)")
        
        self.workout = workout
        self.exercises = workout.exercises
        self.startTime = Date()
        startTimer()
        setupAudioPlayer()
    }
    
    private func setupAudioPlayer() {
        guard let soundURL = Bundle.main.url(forResource: "timer_end", withExtension: "mp3") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: soundURL)
            player?.prepareToPlay()
        } catch {
            print("🔥 오디오 플레이어 초기화 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Timer Management
    private func startTimer() {
        timer?.invalidate() // 기존 타이머 중지
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            // 메인 액터에서 updateTimer 호출
            Task { @MainActor [weak self] in
                self?.updateTimer()
            }
        }
    }
    
    private func updateTimer() {
        let elapsed = Int(Date().timeIntervalSince(startTime))
        minutes = elapsed / 60
        seconds = elapsed % 60
    }
    
    // MARK: - View Mode
    func toggleViewMode() {
        isDetailView.toggle()
    }
    
    // 현재 운동 가져오기
    var currentExercise: WorkoutExercise? {
        guard currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }
    
    // 현재 운동의 세트 수 가져오기
    var currentExerciseSetsCount: Int {
        return currentExercise?.sets.count ?? 0
    }
    
    // 현재 운동의 완료된 세트 수 가져오기
    var completedSetsCountForCurrentExercise: Int {
        guard let exercise = currentExercise else { return 0 }
        return (0..<exercise.sets.count).filter { setIndex in
            isSetCompleted(exerciseIndex: currentExerciseIndex, setIndex: setIndex)
        }.count
    }
    
    // 현재 운동의 진행률 (0.0 ~ 1.0)
    var currentExerciseProgress: Double {
        guard let exercise = currentExercise, !exercise.sets.isEmpty else { return 0 }
        let completedCount = completedSetsCountForCurrentExercise
        return Double(completedCount) / Double(exercise.sets.count)
    }
    
    // 전체 운동의 진행률 (0.0 ~ 1.0)
    var totalWorkoutProgress: Double {
        if exercises.isEmpty { return 0 }
        
        var totalSetsCount = 0
        var completedSetsCountTotal = 0
        
        for (exerciseIndex, exercise) in exercises.enumerated() {
            totalSetsCount += exercise.sets.count
            
            for setIndex in 0..<exercise.sets.count {
                if isSetCompleted(exerciseIndex: exerciseIndex, setIndex: setIndex) {
                    completedSetsCountTotal += 1
                }
            }
        }
        
        return totalSetsCount > 0 ? Double(completedSetsCountTotal) / Double(totalSetsCount) : 0
    }
    
    // 특정 운동까지의 진행률 (0.0 ~ 1.0)
    func progressUpToExercise(index: Int) -> Double {
        if exercises.isEmpty || index < 0 { return 0 }
        
        var completedExercisesCount = 0
        
        for exerciseIndex in 0..<index {
            let exercise = exercises[exerciseIndex]
            let totalSets = exercise.sets.count
            if totalSets == 0 { continue }

            var completedSetsForExercise = 0
            for setIndex in 0..<totalSets {
                if isSetCompleted(exerciseIndex: exerciseIndex, setIndex: setIndex) {
                    completedSetsForExercise += 1
                }
            }
            if completedSetsForExercise == totalSets {
                completedExercisesCount += 1
            }
        }
        
        return exercises.count > 0 ? Double(completedExercisesCount) / Double(exercises.count) : 0
    }
    
    // MARK: - Exercise Navigation
    func previousExercise() {
        withAnimation {
            currentExerciseIndex = max(0, currentExerciseIndex - 1)
            currentSetIndex = 0
        }
    }
    
    func nextExercise() {
        withAnimation {
            currentExerciseIndex = min(exercises.count - 1, currentExerciseIndex + 1)
            currentSetIndex = 0
        }
    }
    
    // MARK: - Set Management
    func toggleSetCompletion(exerciseIndex: Int, setIndex: Int) {
        let key = "\(exerciseIndex)-\(setIndex)"
        if completedSets.contains(key) {
            completedSets.remove(key)
            stopRestTimer()
        } else {
            completedSets.insert(key)
            checkWorkoutCompletion()
            if !showCompletionAlert {
                startRestTimer()
            }
        }
    }
    
    func isSetCompleted(exerciseIndex: Int, setIndex: Int) -> Bool {
        completedSets.contains("\(exerciseIndex)-\(setIndex)")
    }
    
    // MARK: - Exercise Management
    func addExercise() {
        // TODO: 운동 추가 로직 구현
    }
    
    // MARK: - Rest Timer Settings
    func updateRestTime(seconds: Int) {
        restSeconds = seconds
        if isRestTimerActive {
            stopRestTimer()
            startRestTimer()
        }
    }
    
    // 다음 세트로 이동
    func moveToNextSet() {
        stopRestTimer()
        if currentSetIndex < currentExerciseSetsCount - 1 {
            currentSetIndex += 1
        } else if currentExerciseIndex < exercises.count - 1 {
            nextExercise()
        } else {
            checkWorkoutCompletion()
        }
    }
    
    // 이전 세트로 이동
    func moveToPreviousSet() {
        stopRestTimer()
        if currentSetIndex > 0 {
            currentSetIndex -= 1
        } else if currentExerciseIndex > 0 {
            previousExercise()
            currentSetIndex = max(0, exercises[currentExerciseIndex].sets.count - 1)
        }
    }
    
    // MARK: - Rest Timer Management
    func startRestTimer() {
        // UI 업데이트는 메인 액터에서 수행
        guard !isRestTimerActive else { return }
        isRestTimerActive = true
        remainingRestSeconds = restSeconds
        print("⏰ 휴식 타이머 시작: \(restSeconds)초")
        
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate() // self가 없으면 타이머 중지
                return
            }
            
            // 메인 액터에서 UI 관련 작업 수행
            Task { @MainActor in
                if self.remainingRestSeconds > 0 {
                    self.remainingRestSeconds -= 1
                } else {
                    print("🔔 휴식 타이머 종료")
                    // stopRestTimer 내부에서 UI 업데이트가 있으므로 메인 액터에서 호출
                    self.stopRestTimer()
                    self.playTimerEndSound() // 사운드 재생은 백그라운드 가능 (AVAudioPlayer는 스레드 안전)
                    print("➡️ 휴식 후 다음 세트로 이동")
                    // moveToNextSet 내부에서 UI 업데이트가 있으므로 메인 액터에서 호출
                    self.moveToNextSet()
                    // 타이머 종료 후에는 타이머를 무효화해야 함
                    // self 참조가 필요 없으므로 [weak self] 캡처 사용 권장
                    // Task 내에서 timer 직접 참조는 비동기 문제 야기 가능성
                    // -> restTimer 변수를 사용해 외부에서 invalidate 하는 것이 더 안전
                }
            }
        }
    }
    
    // stopRestTimer 내부에서 @Published 프로퍼티를 변경하므로 @MainActor 필요
    @MainActor
    func stopRestTimer() {
        if isRestTimerActive {
            print("🛑 휴식 타이머 중지")
        }
        restTimer?.invalidate()
        restTimer = nil
        // @Published 프로퍼티 변경은 @MainActor 컨텍스트에서 안전
        isRestTimerActive = false
        remainingRestSeconds = restSeconds
    }
    
    private func playTimerEndSound() {
        print("🔊 타이머 종료음 재생 시도")
        player?.play()
    }
    
    // MARK: - Workout Completion
    private func checkWorkoutCompletion() {
        if totalWorkoutProgress >= 1.0 {
            print("�� 워크아웃 완료! 확인 알림 표시 준비.")
            stopTimer()
            stopRestTimer()
            showCompletionAlert = true
        }
    }
    
    // Called when the user confirms completion from the alert
    func confirmWorkoutCompletion() {
        print("✅ 사용자가 워크아웃 완료 확인")
        let finalElapsedTime = Date().timeIntervalSince(startTime)
        let completedSession = WorkoutSessionModel(
            workout: workout,
            startTime: startTime,
            elapsedTime: finalElapsedTime,
            completedSets: completedSets
        )
        
        AppWorkoutManager.shared.completeWorkout(session: completedSession)
        
        stopTimer()
        stopRestTimer()
    }
    
    // Helper to stop the main workout timer
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        print("⏱️ 메인 워크아웃 타이머 중지")
    }
    
    // MARK: - Cleanup
    deinit {
        print("🧹 WorkoutSessionViewModel 해제됨")
        // deinit에서는 타이머를 직접 무효화하는 것이 가장 안전합니다.
        // invalidate()는 스레드 안전합니다.
        timer?.invalidate()
        restTimer?.invalidate()
        // Task나 @MainActor 관련 메서드 호출은 피합니다.
    }
}
