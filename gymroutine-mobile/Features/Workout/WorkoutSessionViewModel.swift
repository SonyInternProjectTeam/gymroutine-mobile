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
    @Published var exercises: [WorkoutExercise]
    @Published var minutes: Int = 0
    @Published var seconds: Int = 0
    @Published var currentExerciseIndex: Int = 0
    @Published var completedSets: Set<String> = []  // "exerciseIndex-setIndex" 형식으로 저장
    @Published var isDetailView: Bool = true  // true: 상세 화면, false: 리스트 화면
    @Published var currentSetIndex: Int = 0  // 현재 운동의 현재 세트 인덱스
    
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
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
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
    var completedSetsCount: Int {
        guard let exercise = currentExercise else { return 0 }
        return (0..<exercise.sets.count).filter { setIndex in
            isSetCompleted(exerciseIndex: currentExerciseIndex, setIndex: setIndex)
        }.count
    }
    
    // 현재 운동의 진행률 (0.0 ~ 1.0)
    var currentExerciseProgress: Double {
        guard let exercise = currentExercise, !exercise.sets.isEmpty else { return 0 }
        return Double(completedSetsCount) / Double(exercise.sets.count)
    }
    
    // 전체 운동의 진행률 (0.0 ~ 1.0)
    var totalWorkoutProgress: Double {
        if exercises.isEmpty { return 0 }
        
        var totalSets = 0
        var completedSets = 0
        
        for (exerciseIndex, exercise) in exercises.enumerated() {
            totalSets += exercise.sets.count
            
            for setIndex in 0..<exercise.sets.count {
                if isSetCompleted(exerciseIndex: exerciseIndex, setIndex: setIndex) {
                    completedSets += 1
                }
            }
        }
        
        return totalSets > 0 ? Double(completedSets) / Double(totalSets) : 0
    }
    
    // 특정 운동까지의 진행률 (0.0 ~ 1.0)
    func progressUpToExercise(index: Int) -> Double {
        if exercises.isEmpty || index < 0 { return 0 }
        
        var exercisesBeforeIndex = 0
        var totalExercises = 0
        
        for (exerciseIndex, exercise) in exercises.enumerated() {
            if exerciseIndex < index {
                exercisesBeforeIndex += 1
            }
            totalExercises += 1
        }
        
        return totalExercises > 0 ? Double(exercisesBeforeIndex) / Double(totalExercises) : 0
    }
    
    // MARK: - Exercise Navigation
    func previousExercise() {
        withAnimation {
            currentExerciseIndex = max(0, currentExerciseIndex - 1)
        }
    }
    
    func nextExercise() {
        withAnimation {
            currentExerciseIndex = min(exercises.count - 1, currentExerciseIndex + 1)
        }
    }
    
    // MARK: - Set Management
    func toggleSetCompletion(exerciseIndex: Int, setIndex: Int) {
        let key = "\(exerciseIndex)-\(setIndex)"
        if completedSets.contains(key) {
            completedSets.remove(key)
            stopRestTimer()  // 체크를 해제하면 휴식 타이머도 중지
        } else {
            completedSets.insert(key)
            startRestTimer()  // 세트를 완료하면 휴식 타이머 시작
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
        if currentSetIndex < currentExerciseSetsCount - 1 {
            currentSetIndex += 1
        } else if currentExerciseIndex < exercises.count - 1 {
            // 다음 운동으로 이동
            currentExerciseIndex += 1
            currentSetIndex = 0
        }
    }
    
    // 이전 세트로 이동
    func moveToPreviousSet() {
        if currentSetIndex > 0 {
            currentSetIndex -= 1
        } else if currentExerciseIndex > 0 {
            // 이전 운동으로 이동
            currentExerciseIndex -= 1
            currentSetIndex = max(0, exercises[currentExerciseIndex].sets.count - 1)
        }
    }
    
    // 세트 완료 토글 및 자동 이동
    func toggleSetCompletionWithAutoAdvance(exerciseIndex: Int, setIndex: Int) {
        toggleSetCompletion(exerciseIndex: exerciseIndex, setIndex: setIndex)
        
        // 세트가 완료되면 다음 세트로 자동 이동 (휴식 타이머 후)
        if isSetCompleted(exerciseIndex: exerciseIndex, setIndex: setIndex) {
            // 다음 세트로 이동하는 코드는 휴식 타이머가 끝난 후 실행됨
        }
    }
    
    // MARK: - Rest Timer Management
    func startRestTimer() {
        isRestTimerActive = true
        remainingRestSeconds = restSeconds
        
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.remainingRestSeconds > 0 {
                self.remainingRestSeconds -= 1
            } else {
                self.stopRestTimer()
                self.playTimerEndSound()
                // 휴식 타이머가 끝나면 다음 세트로 이동
                self.moveToNextSet()
            }
        }
    }
    
    func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        isRestTimerActive = false
    }
    
    private func playTimerEndSound() {
        player?.play()
    }
    
    // MARK: - Cleanup
    deinit {
        timer?.invalidate()
        restTimer?.invalidate()
    }
}
