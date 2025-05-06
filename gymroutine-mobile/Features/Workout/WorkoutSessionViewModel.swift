//
//  WorkoutSessionViewModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/04/03.
//

import SwiftUI
import AVFoundation
import FirebaseFirestore

@MainActor
final class WorkoutSessionViewModel: ObservableObject {
    // MARK: - Properties
    @Published var workout: Workout
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
    // 총 휴식 시간 추적을 위한 변수
    private var restStartTime: Date?
    private var totalRestTime: TimeInterval = 0
    
    // 추가된 UI 관련 속성
    @Published var showAddExerciseSheet = false
    @Published var showEditSetSheet = false
    @Published var editingSetInfo: (exerciseIndex: Int, setIndex: Int, weight: Double, reps: Int)? = nil
    
    // WorkoutExercisesManager 인스턴스 (합성 패턴)
    var exercisesManager = WorkoutExercisesManager()
    
    private var timer: Timer?
    var startTime: Date
    private let workoutService = WorkoutService()
    
    // MARK: - Initialization
    init(workout: Workout) {
        print("📱 WorkoutSessionViewModel 초기화됨")
        print("📱 전달받은 워크아웃: \(workout.name), 운동 개수: \(workout.exercises.count)")
        
        self.workout = workout
        self.startTime = Date()
        startTimer()
        setupAudioPlayer()

        // Initialize session state
        currentExerciseIndex = 0
        currentSetIndex = 0
        updateRestTimeFromCurrentExercise() // Initialize rest time based on the first exercise
        stopRestTimer() // Ensure rest timer isn't running initially
        
        // 운동 목록을 exercisesManager에도 설정 (복원)
        exercisesManager.exercises = workout.exercises
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
        guard currentExerciseIndex < exercisesManager.exercises.count else { return nil }
        return exercisesManager.exercises[currentExerciseIndex]
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
        if exercisesManager.exercises.isEmpty { return 0 }
        
        var totalSetsCount = 0
        var completedSetsCountTotal = 0
        
        for (exerciseIndex, exercise) in exercisesManager.exercises.enumerated() {
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
        if exercisesManager.exercises.isEmpty || index < 0 { return 0 }
        
        var completedExercisesCount = 0
        
        for exerciseIndex in 0..<index {
            let exercise = exercisesManager.exercises[exerciseIndex]
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
        
        return exercisesManager.exercises.count > 0 ? Double(completedExercisesCount) / Double(exercisesManager.exercises.count) : 0
    }
    
    // MARK: - Exercise Navigation
    func previousExercise() {
        withAnimation {
            currentExerciseIndex = max(0, currentExerciseIndex - 1)
            currentSetIndex = 0
            updateRestTimeFromCurrentExercise()
        }
    }
    
    func nextExercise() {
        withAnimation {
            currentExerciseIndex = min(exercisesManager.exercises.count - 1, currentExerciseIndex + 1)
            currentSetIndex = 0
            updateRestTimeFromCurrentExercise()
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
        // 상태가 변경될 때마다 Firebase에 저장
        saveExercisesToFirestore()
    }
    
    func isSetCompleted(exerciseIndex: Int, setIndex: Int) -> Bool {
        completedSets.contains("\(exerciseIndex)-\(setIndex)")
    }
    
    // 현재 운동에 세트 추가 (복원)
    func addSetToCurrentExercise() {
        guard let currentExercise = currentExercise, 
              let index = exercisesManager.exercises.firstIndex(where: { $0.id == currentExercise.id }) else { return }
        
        // 마지막 세트 정보 복사 또는 기본값 사용
        let lastSet = currentExercise.sets.last
        let newSet = ExerciseSet(
            reps: lastSet?.reps ?? 10,
            weight: lastSet?.weight ?? 50.0
        )
        
        var updatedExercise = currentExercise
        updatedExercise.sets.append(newSet)
        exercisesManager.updateExerciseSet(for: updatedExercise)
        
        print("✅ 세트 추가됨: \(currentExercise.name)")
        
        // 세션 중 변경사항을 Firestore에 저장
        saveExercisesToFirestore()
    }

    func addSetToExercise(at index: Int) {
        guard exercisesManager.exercises.indices.contains(index) else { return }

        var exercise = exercisesManager.exercises[index]

        // 最後のセット情報をコピー、またはデフォルト値
        let lastSet = exercise.sets.last
        let newSet = ExerciseSet(
            reps: lastSet?.reps ?? 10,
            weight: lastSet?.weight ?? 50.0
        )

        exercise.sets.append(newSet)
        exercisesManager.updateExerciseSet(for: exercise)

        print("✅ セット追加: \(exercise.name)")

        saveExercisesToFirestore()
    }

    // 세트 삭제 (복원)
    func removeSet(exerciseIndex: Int, setIndex: Int) {
        guard exerciseIndex < exercisesManager.exercises.count,
              setIndex < exercisesManager.exercises[exerciseIndex].sets.count else { return }
        
        var updatedExercise = exercisesManager.exercises[exerciseIndex]
        updatedExercise.sets.remove(at: setIndex)
        exercisesManager.updateExerciseSet(for: updatedExercise)

        // 관련 완료 상태 제거
        let key = "\(exerciseIndex)-\(setIndex)"
        completedSets.remove(key)
        
        // 더 높은 인덱스의 세트에 대한 완료 상태 인덱스 조정
        let prefix = "\(exerciseIndex)-"
        let keysToUpdate = completedSets.filter { $0.hasPrefix(prefix) }
        
        for oldKey in keysToUpdate {
            if let range = oldKey.range(of: prefix),
               let oldSetIndex = Int(oldKey[range.upperBound...]),
               oldSetIndex > setIndex {
                completedSets.remove(oldKey)
                let newKey = "\(exerciseIndex)-\(oldSetIndex - 1)"
                completedSets.insert(newKey)
            }
        }
        
        // 현재 세트 인덱스 조정
        if currentSetIndex >= setIndex && currentSetIndex > 0 {
            currentSetIndex -= 1
        }
        
        print("❌ 세트 삭제됨: \(exercisesManager.exercises[exerciseIndex].name) 세트 #\(setIndex + 1)")
        
        // 세션 중 변경사항을 Firestore에 저장
        saveExercisesToFirestore()
    }
    
    // 세트 정보 편집 시트 표시 (복원)
    func showEditSetInfo(exerciseIndex: Int, setIndex: Int) {
        guard exerciseIndex < exercisesManager.exercises.count,
              setIndex < exercisesManager.exercises[exerciseIndex].sets.count else { return }
        
        let set = exercisesManager.exercises[exerciseIndex].sets[setIndex]
        editingSetInfo = (exerciseIndex, setIndex, set.weight, set.reps)
        showEditSetSheet = true
    }
    
    // 세트 정보 업데이트 (복원)
    func updateSetInfo(weight: Double, reps: Int) {
        guard let info = editingSetInfo else { return }
        
        var updatedExercise = exercisesManager.exercises[info.exerciseIndex]
        var updatedSet = updatedExercise.sets[info.setIndex]
        updatedSet.weight = weight
        updatedSet.reps = reps
        
        updatedExercise.sets[info.setIndex] = updatedSet
        exercisesManager.updateExerciseSet(for: updatedExercise)

        print("✏️ 세트 정보 업데이트: \(updatedExercise.name) 세트 #\(info.setIndex + 1) - \(weight)kg, \(reps)회")
        
        // 세션 중 변경사항을 Firestore에 저장
        saveExercisesToFirestore()
        
        // 편집 정보 초기화
        editingSetInfo = nil
    }
    
    // 현재 세트를 완료하고 다음 세트로 이동 (복원)
    func completeCurrentSetAndMoveToNext() {
        // 현재 세트 완료 처리
        if !isSetCompleted(exerciseIndex: currentExerciseIndex, setIndex: currentSetIndex) {
            toggleSetCompletion(exerciseIndex: currentExerciseIndex, setIndex: currentSetIndex)
        }
        
        // 다음 세트로 이동
        moveToNextSet()
    }
    
    // MARK: - Rest Timer Management
    func startRestTimer() {
        // UI 업데이트는 메인 액터에서 수행
        guard !isRestTimerActive else { return }
        isRestTimerActive = true
        remainingRestSeconds = restSeconds
        print("⏰ 휴식 타이머 시작: \(restSeconds)초")
        
        // 휴식 시작 시간 기록
        restStartTime = Date()
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
            
            // 휴식 시간 계산 및 추가
            if let startTime = restStartTime {
                let restDuration = Date().timeIntervalSince(startTime)
                totalRestTime += restDuration
                print("⏱️ 휴식 지속 시간: \(Int(restDuration))초, 총 휴식 시간: \(Int(totalRestTime))초")
                restStartTime = nil
            }
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
            print(" 워크아웃 완료! 확인 알림 표시 준비.")
            stopTimer()
            stopRestTimer()
            showCompletionAlert = true
        }
    }
    
    // Called when the user confirms completion from the alert
    func confirmWorkoutCompletion() {
        print("✅ 사용자가 워크아웃 완료 확인")
        
        // 최종 상태를 Firestore에 저장
        saveExercisesToFirestore()
        
        // 세션 중 업데이트된 운동 정보로 새 워크아웃 모델 생성
        let updatedWorkout = Workout(
            id: workout.id,
            userId: workout.userId,
            name: workout.name,
            createdAt: workout.createdAt,
            notes: workout.notes,
            isRoutine: workout.isRoutine,
            scheduledDays: workout.scheduledDays,
            exercises: exercisesManager.exercises
        )
        
        let finalElapsedTime = Date().timeIntervalSince(startTime)
        let completedSession = WorkoutSessionModel(
            workout: updatedWorkout,  // 업데이트된 워크아웃 정보 사용
            startTime: startTime,
            elapsedTime: finalElapsedTime,
            completedSets: completedSets,
            totalRestTime: totalRestTime
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
    
    // 운동 추가 시트 표시 (이름 변경됨)
    func presentAddExerciseSheet() {
        showAddExerciseSheet = true
    }
    
    // Firestore에 업데이트된 운동 정보 저장 (복원)
    private func saveExercisesToFirestore() {
        guard let workoutId = workout.id else {
            print("❌ WorkoutID가 없어서 저장 불가")
            return
        }
        
        Task {
            let result = await workoutService.updateWorkoutExercises(workoutID: workoutId, exercises: exercisesManager.exercises)
            switch result {
            case .success:
                print("✅ 변경사항이 Firestore에 저장되었습니다")
            case .failure(let error):
                print("🔥 Firestore 저장 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Exercise Management (Placeholder - needs implementation or removal)
    func addExercise() {
        // TODO: 운동 추가 로직 구현 - This needs to integrate with ExerciseSearchView or be removed
        // For now, let's just show the sheet using the manager
        presentAddExerciseSheet()
    }
    
    // MARK: - Rest Timer Settings
    func updateRestTime(seconds: Int) {
        restSeconds = seconds
        if isRestTimerActive {
            stopRestTimer()
            startRestTimer()
        }
    }
    
    // Helper method to update rest time based on current exercise
    func updateRestTimeFromCurrentExercise() {
        guard currentExerciseIndex < exercisesManager.exercises.count else { return }
        
        let exercise = exercisesManager.exercises[currentExerciseIndex]
        if let customRestTime = exercise.restTime {
            restSeconds = customRestTime
            remainingRestSeconds = customRestTime
            print("🕒 Using custom rest time for \(exercise.name): \(customRestTime)s")
        } else {
            // Default rest time if not specified
            restSeconds = 90
            remainingRestSeconds = 90
            print("🕒 Using default rest time: 90s")
        }
    }
    
    // 다음 세트로 이동
    func moveToNextSet() {
        stopRestTimer()
        if currentSetIndex < currentExerciseSetsCount - 1 {
            currentSetIndex += 1
        } else if currentExerciseIndex < exercisesManager.exercises.count - 1 {
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
            currentSetIndex = max(0, exercisesManager.exercises[currentExerciseIndex].sets.count - 1)
        }
    }
    
    // 지정된 인덱스의 운동 휴식 시간 업데이트
    func updateRestTimeForExercise(at index: Int, seconds: Int) {
        guard index >= 0 && index < exercisesManager.exercises.count else {
            print("🔥 Invalid index for updating rest time: \(index)")
            return
        }
        var exerciseToUpdate = exercisesManager.exercises[index]
        exerciseToUpdate.restTime = seconds
        exercisesManager.updateExerciseSet(for: exerciseToUpdate) // Use manager's update method
        
        // 명시적으로 Firebase에 저장
        print("휴식 시간 업데이트 중: \(exerciseToUpdate.name)의 휴식 시간이 \(seconds)초로 설정됨. Firebase에 저장 시도...")
        saveWorkoutExercises()
        
        // Update the main timer variables if the current exercise was updated
        if index == currentExerciseIndex {
            updateRestTimeFromCurrentExercise() 
            // If rest timer is active, optionally restart it
            if isRestTimerActive {
                 print("🔄 Restarting active rest timer with new time: \(seconds)s")
                 stopRestTimer()
                 startRestTimer()
             }
        }
        print("🕒 Rest time updated for exercise at index \(index) to \(seconds)s")
    }
    
    // RestTimeSettingsView에서 사용할 수 있는 바인딩 생성
    func bindingForExercise(at index: Int) -> Binding<WorkoutExercise> {
        return Binding<WorkoutExercise>(
            get: {
                guard index < self.exercisesManager.exercises.count else {
                    // 안전장치: 인덱스가 범위를 벗어나면 빈 운동을 반환
                    return WorkoutExercise(
                        name: "",
                        part: "",
                        key: "",
                        sets: [],
                        restTime: 90
                    )
                }
                return self.exercisesManager.exercises[index]
            },
            set: { newValue in
                guard index < self.exercisesManager.exercises.count else { return }
                
                // 운동 객체 업데이트
                self.exercisesManager.exercises[index] = newValue
                
                // 중요: 명시적으로 Firebase에 저장 (restTime 변경이 적용되도록)
                print("바인딩을 통해 WorkoutExercise 업데이트됨. 변경사항 저장 시도: \(newValue.name), 휴식 시간: \(newValue.restTime ?? 0)초")
                
                // 데이터베이스에 변경사항 저장
                self.saveWorkoutExercises()
                
                // UI 갱신을 위한 objectWillChange 발행
                self.objectWillChange.send()
            }
        )
    }
    
    // 운동 데이터를 데이터베이스에 저장
    func saveWorkoutExercises() {
        // 워크아웃 문서 참조 얻기
        guard let workoutID = workout.id else { return }
        let workoutRef = Firestore.firestore().collection("workouts").document(workoutID)
        
        // 운동 데이터를 맵으로 변환
        let exercisesData = exercisesManager.exercises.map { exercise -> [String: Any] in
            var exerciseData: [String: Any] = [
                "name": exercise.name,
                "part": exercise.part,
                "sets": exercise.sets.map { set -> [String: Any] in
                    let setData: [String: Any] = [
                        "weight": set.weight,
                        "reps": set.reps
                    ]
                    return setData
                }
            ]
            
            // 휴식 시간이 있는 경우 추가
            if let restTime = exercise.restTime {
                exerciseData["restTime"] = restTime
            }
            
            return exerciseData
        }
        
        // 데이터베이스 업데이트
        workoutRef.updateData(["exercises": exercisesData]) { error in
            if let error = error {
                print("Error updating workout exercises: \(error.localizedDescription)")
            } else {
                print("Workout exercises successfully updated")
            }
        }
    }
    
    // 총 휴식 시간 반환
    func getTotalRestTime() -> TimeInterval {
        // 현재 진행 중인 휴식 시간이 있다면 추가
        if isRestTimerActive, let startTime = restStartTime {
            let currentRestDuration = Date().timeIntervalSince(startTime)
            return totalRestTime + currentRestDuration
        }
        return totalRestTime
    }
}
