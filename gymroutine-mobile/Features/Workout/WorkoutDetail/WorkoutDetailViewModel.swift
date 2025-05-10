//
//  WorkoutDetailViewModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/04/01.
//

import SwiftUI

@MainActor
final class WorkoutDetailViewModel: WorkoutExercisesManager {
    @Published var workout: Workout
    @Published var workoutSortFlg = false
    @Published var searchExercisesFlg = false
    @Published var editExerciseSetsFlg = false
    @Published var selectedIndex: Int? = nil
    @Published var showWorkoutSession = false  // 워크아웃 세션 화면 표시 여부
    @Published var isWorkoutInProgress = false // 워크아웃 진행 중 여부
    @Published var workoutSessionViewModel: WorkoutSessionViewModel? // 워크아웃 세션 뷰모델 참조
    @Published var showMiniWorkoutSession = false // 최소화된 워크아웃 세션 표시 여부
    // 휴식 시간 설정 관련 속성
    @Published var showRestTimeSettingsSheet = false
    @Published var selectedRestTimeIndex: Int? = nil
    
    // 편집 화면 표시 플래그
    @Published var showEditView = false
    
    private let service = WorkoutService()
    private let workoutManager = AppWorkoutManager.shared
    private let userManager = UserManager.shared
    
    /// 현재 사용자가 워크아웃의 소유자인지 확인하는 속성
    var isCurrentUser: Bool {
        guard let currentUser = userManager.currentUser else {
            return false
        }
        return workout.userId == currentUser.uid
    }
    
    init(workout: Workout) {
        self.workout = workout
        super.init()
        self.exercises = workout.exercises
    }
    
    /// 워크아웃 데이터를 Firestore에서 다시 불러오는 메서드
    func refreshWorkoutData() {
        guard let workoutId = workout.id else {
            print("Error: Cannot refresh workout without ID")
            return
        }
        
        Task {
            UIApplication.showLoading()
            let response = await service.fetchWorkoutById(workoutID: workoutId)
            switch response {
            case .success(let refreshedWorkout):
                self.workout = refreshedWorkout
                self.exercises = refreshedWorkout.exercises
            case .failure(let error):
                print("[ERROR] \(error.localizedDescription)")
                UIApplication.showBanner(type: .error, message: "データの更新に失敗しました")
            }
            UIApplication.hideLoading()
        }
    }
    
    func moveExercise(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
    }
    
    /// 워크아웃 편집 액션 (예: 편집 화면으로 이동)
    func editWorkout() {
        guard isCurrentUser else {
            UIApplication.showBanner(type: .error, message: "他のユーザーのワークアウトは編集できません")
            return
        }
        // 편집 화면 표시
        showEditView = true
    }
    
    /// 새 운동 추가 액션
    func addExercise() {
        guard isCurrentUser else {
            UIApplication.showBanner(type: .error, message: "他のユーザーのワークアウトにエクササイズを追加できません")
            return
        }
        // 운동 검색 시트를 보여줌
        searchExercisesFlg = true
    }
    
    /// 워크아웃 시작 액션
    func startWorkout() {
        guard isCurrentUser else {
            UIApplication.showBanner(type: .error, message: "他のユーザーのワークアウトを実行できません")
            return
        }
        
        print("📱 워크아웃 시작 버튼이 클릭되었습니다.")
        
        // data sync before start workout
        Task {
            do {
                // sync data before start workout
                try await refreshWorkoutDataSync()
                // start workout with latest data
                workoutManager.startWorkout(workout: workout)
                
                // refresh data after workout (when come back from workout session) 
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.refreshWorkoutData()
                    print("🔄 워크아웃 세션 후 데이터 새로고침 예약됨")
                }
            } catch {
                print("🔥 워크아웃 시작 전 데이터 동기화 실패: \(error)")
                // even if failed, start workout
                workoutManager.startWorkout(workout: workout)
            }
        }
    }
    
    /// CreateWorkoutViewModel에서 상속받은 appendExercise 메서드를 오버라이드하여 
    /// 파이어스토어에 업데이트하는 로직을 추가
    override func appendExercise(exercise: Exercise) {
        // 부모 클래스의 메서드를 호출하여 로컬 exercises 배열에 추가
        super.appendExercise(exercise: exercise)
        
        // Firestore에 업데이트
        saveExercisesToFirestore()
    }
    
    /// 로컬 exercises 배열을 Firestore에 저장
    func saveExercisesToFirestore() {
        guard let workoutId = workout.id else {
            print("Error: Cannot update workout without ID")
            return
        }
        
        Task {
            UIApplication.showLoading()
            let result = await service.updateWorkoutExercises(workoutID: workoutId, exercises: exercises)
            switch result {
            case .success():
                print("✅ 워크아웃 exercises 업데이트 성공")
                // 'exercises' is a let constant in Workout model, so we can't modify it directly
                // workout.exercises = exercises
            case .failure(let error):
                print("🔥 워크아웃 exercises 업데이트 실패: \(error.localizedDescription)")
                UIApplication.showBanner(type: .error, message: "エクササイズの追加に失敗しました")
            }
            UIApplication.hideLoading()
        }
    }
    
    /// removeExercise도 오버라이드하여 Firestore에 업데이트
    override func removeExercise(_ workoutExercise: WorkoutExercise) {
        guard isCurrentUser else {
            UIApplication.showBanner(type: .error, message: "他のユーザーのワークアウトは編集できません")
            return
        }
        
        super.removeExercise(workoutExercise)
        // 삭제 작업은 동기적으로 처리하여 바로 시작해도 반영되도록 함
        Task {
            do {
                try await saveExercisesToFirestoreSync()
                print("✅ 운동 삭제 후 즉시 Firestore 동기화 완료")
            } catch {
                print("🔥 운동 삭제 후 Firestore 동기화 실패: \(error)")
            }
        }
    }
    
    /// 운동 세트 수정을 위한 메서드
    func onClickedExerciseSets(index: Int) {
        guard isCurrentUser else {
            UIApplication.showBanner(type: .error, message: "他のユーザーのワークアウトは編集できません")
            return
        }
        
        selectedIndex = index
        editExerciseSetsFlg = true
    }
    
    /// 운동 세트가 변경되었을 때 Firestore에 저장
    func updateExerciseSetAndSave(for workoutExercise: WorkoutExercise) {
        guard isCurrentUser else {
            UIApplication.showBanner(type: .error, message: "他のユーザーのワークアウトは編集できません")
            return
        }
        
        // 기존 코드에 더 명확한 로깅 추가
        print("🔍 세트 업데이트 전: \(workoutExercise.name)의 세트: \(workoutExercise.sets)")
        
        updateExerciseSet(for: workoutExercise)
        
        // updateExerciseSet 호출 후 로깅을 통해 변경 확인
        if let index = exercises.firstIndex(where: { $0.id == workoutExercise.id }) {
            print("✅ 세트 업데이트 후: \(exercises[index].name)의 세트: \(exercises[index].sets)")
        }
        
        // Firestore에 변경 사항 저장
        saveExercisesToFirestore()
        
        // 모달을 닫고 세트 값이 제대로 업데이트되었는지 확인
        editExerciseSetsFlg = false
    }
    
    /// 휴식 시간 설정 모달을 표시
    func showRestTimeSettings(for index: Int) {
        guard isCurrentUser else {
            UIApplication.showBanner(type: .error, message: "他のユーザーのワークアウトは編集できません")
            return
        }
        
        selectedRestTimeIndex = index
        showRestTimeSettingsSheet = true
    }
    
    // 지정된 인덱스의 운동 휴식 시간 업데이트 및 저장
    func updateRestTimeForExercise(at index: Int, seconds: Int) {
        guard index >= 0 && index < exercises.count else {
            print("🔥 Invalid index for updating rest time: \(index)")
            return
        }
        
        // 로컬 배열 업데이트 (exercises는 let이므로 직접 수정 불가, ViewModel의 exercises 사용)
        var exerciseToUpdate = self.exercises[index]
        exerciseToUpdate.restTime = seconds
        self.exercises[index] = exerciseToUpdate // Update the ViewModel's @Published array
        
        print("🕒 Rest time for exercise '\(exerciseToUpdate.name)' updated locally to \(seconds)s. Saving to Firestore...")

        // Firestore에 변경 사항 저장
        saveExercisesToFirestore() 
    }
    
    /// Firebase에 동기적으로 저장하는 메서드
    private func saveExercisesToFirestoreSync() async throws {
        guard let workoutId = workout.id else {
            print("Error: Cannot update workout without ID")
            throw NSError(domain: "WorkoutDetailViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "워크아웃 ID가 없습니다."])
        }
        
        UIApplication.showLoading()
        let result = await service.updateWorkoutExercises(workoutID: workoutId, exercises: exercises)
        UIApplication.hideLoading()
        
        switch result {
        case .success():
            print("✅ 워크아웃 exercises 동기적 업데이트 성공")
            return
        case .failure(let error):
            print("🔥 워크아웃 exercises 동기적 업데이트 실패: \(error.localizedDescription)")
            UIApplication.showBanner(type: .error, message: "エクササイズの更新に失敗しました")
            throw error
        }
    }
    
    /// Firebase에서 동기적으로 데이터 새로고침
    private func refreshWorkoutDataSync() async throws {
        guard let workoutId = workout.id else {
            print("Error: Cannot refresh workout without ID")
            throw NSError(domain: "WorkoutDetailViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "워크아웃 ID가 없습니다."])
        }
        
        UIApplication.showLoading()
        let response = await service.fetchWorkoutById(workoutID: workoutId)
        switch response {
        case .success(let refreshedWorkout):
            self.workout = refreshedWorkout
            self.exercises = refreshedWorkout.exercises
        case .failure(let error):
            UIApplication.showBanner(type: .error, message: "データの更新に失敗しました")
            throw error
        }
        UIApplication.hideLoading()
    }
}