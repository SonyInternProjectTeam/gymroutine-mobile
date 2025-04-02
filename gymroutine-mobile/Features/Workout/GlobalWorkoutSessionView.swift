import SwiftUI

struct GlobalWorkoutSessionView: View {
    @ObservedObject var workoutManager = AppWorkoutManager.shared
    
    var body: some View {
        // ワークアウトセッションモーダルのみ管理
        WorkoutSessionContainerView()
            .sheet(isPresented: Binding<Bool>(
                get: { workoutManager.isWorkoutSessionActive && workoutManager.isWorkoutSessionMaximized },
                set: { newValue in
                    if !newValue && workoutManager.isWorkoutSessionActive {
                        workoutManager.minimizeWorkoutSession()
                    }
                }
            )) {
                if let sessionViewModel = workoutManager.workoutSessionViewModel {
                    WorkoutSessionView(
                        viewModel: sessionViewModel,
                        onEndWorkout: {
                            workoutManager.endWorkout()
                        }
                    )
                    .presentationDragIndicator(.visible)
                    .interactiveDismissDisabled(false)
                    .onDisappear {
                        if workoutManager.isWorkoutSessionActive {
                            workoutManager.minimizeWorkoutSession()
                        }
                    }
                }
            }
    }
}

// 実際のコンテンツを含まないコンテナビュー
struct WorkoutSessionContainerView: View {
    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
    }
} 