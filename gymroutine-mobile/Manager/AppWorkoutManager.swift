import SwiftUI

@MainActor
class AppWorkoutManager: ObservableObject {
    static let shared = AppWorkoutManager()
    
    @Published var isWorkoutSessionActive = false
    @Published var isWorkoutSessionMaximized = false
    @Published var currentWorkout: Workout?
    @Published var workoutSessionViewModel: WorkoutSessionViewModel?
    
    // 下位互換性のためのプロパティ
    var isWorkoutInProgress: Bool { isWorkoutSessionActive }
    var showWorkoutSession: Bool { 
        get { isWorkoutSessionActive && isWorkoutSessionMaximized }
        set { 
            if newValue {
                isWorkoutSessionActive = true
                isWorkoutSessionMaximized = true
            } else {
                isWorkoutSessionMaximized = false
            }
        }
    }
    var showMiniWorkoutSession: Bool {
        get { isWorkoutSessionActive && !isWorkoutSessionMaximized }
        set { 
            if newValue {
                isWorkoutSessionActive = true
                isWorkoutSessionMaximized = false
            } else {
                isWorkoutSessionMaximized = true
            }
        }
    }
    
    private init() {}
    
    // ワークアウト開始
    func startWorkout(workout: Workout) {
        let sessionViewModel = WorkoutSessionViewModel(workout: workout)
        workoutSessionViewModel = sessionViewModel
        currentWorkout = workout
        isWorkoutSessionActive = true
        isWorkoutSessionMaximized = true
        print("📱 AppWorkoutManager: ワークアウトセッション開始")
    }
    
    // ワークアウトセッションを閉じる - 最小化モードに切り替え
    func minimizeWorkoutSession() {
        isWorkoutSessionMaximized = false
        print("📱 AppWorkoutManager: ワークアウトセッション最小化")
    }
    
    // 最小化されたワークアウトセッションを開く
    func maximizeWorkoutSession() {
        isWorkoutSessionMaximized = true
        print("📱 AppWorkoutManager: ワークアウトセッション最大化")
    }
    
    // ワークアウト終了
    func endWorkout() {
        isWorkoutSessionActive = false
        isWorkoutSessionMaximized = false
        workoutSessionViewModel = nil
        currentWorkout = nil
        print("📱 AppWorkoutManager: ワークアウトセッション終了")
    }
} 