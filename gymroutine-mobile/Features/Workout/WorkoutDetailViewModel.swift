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
    @Published var searchExercisesFlg = false
    @Published var editExerciseSetsFlg = false
    @Published var selectedIndex: Int? = nil
    @Published var showWorkoutSession = false  // 워크아웃 세션 화면 표시 여부
    @Published var isWorkoutInProgress = false // 워크아웃 진행 중 여부
    @Published var workoutSessionViewModel: WorkoutSessionViewModel? // 워크아웃 세션 뷰모델 참조
    @Published var showMiniWorkoutSession = false // 최소화된 워크아웃 세션 표시 여부
    
    // 편집 화면 표시 플래그
    @Published var showEditView = false
    
    private let service = WorkoutService()
    private let workoutManager = AppWorkoutManager.shared
    
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
            do {
                let refreshedWorkout = try await service.fetchWorkoutById(workoutID: workoutId)
                await MainActor.run {
                    self.workout = refreshedWorkout
                    self.exercises = refreshedWorkout.exercises
                    print("✅ 워크아웃 데이터 새로고침 완료")
                }
            } catch {
                print("🔥 워크아웃 새로고침 실패: \(error.localizedDescription)")
                UIApplication.showBanner(type: .error, message: "データの更新に失敗しました")
            }
            UIApplication.hideLoading()
        }
    }
    
    /// 워크아웃 편집 액션 (예: 편집 화면으로 이동)
    func editWorkout() {
        // 편집 화면 표시
        showEditView = true
    }
    
    /// 새 운동 추가 액션
    func addExercise() {
        // 운동 검색 시트를 보여줌
        searchExercisesFlg = true
    }
    
    /// 워크아웃 시작 액션
    func startWorkout() {
        print("📱 워크아웃 시작 버튼이 클릭되었습니다.")
        workoutManager.startWorkout(workout: workout)
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
    private func saveExercisesToFirestore() {
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
        super.removeExercise(workoutExercise)
        saveExercisesToFirestore()
    }
    
    /// 운동 세트 수정을 위한 메서드
    func onClickedExerciseSets(index: Int) {
        selectedIndex = index
        editExerciseSetsFlg = true
    }
    
    /// 운동 세트가 변경되었을 때 Firestore에 저장
    func updateExerciseSetAndSave(for workoutExercise: WorkoutExercise) {
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
}
