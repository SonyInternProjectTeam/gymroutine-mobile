import SwiftUI

struct GlobalWorkoutSessionView: View {
    @StateObject private var workoutManager = AppWorkoutManager.shared
    
    var body: some View {
        // 빈 뷰 또는 기존 뷰 구조 (예: ZStack)
        // 이 뷰는 주로 다른 뷰 위에 모달을 표시하는 역할을 합니다.
        Color.clear // 투명 배경 또는 필요에 따른 컨테이너
            .frame(width: 0, height: 0) // 화면에 영향을 주지 않도록 크기 최소화

            // 워크아웃 세션 모달 (기존 로직)
            .sheet(isPresented: $workoutManager.isWorkoutSessionMaximized) {
                if let viewModel = workoutManager.workoutSessionViewModel {
                    // NavigationStack을 추가하여 WorkoutSessionView 내 타이틀 등이 표시되도록 함
                    NavigationStack {
                        WorkoutSessionView(viewModel: viewModel, onEndWorkout: {
                            // '종료' 버튼 액션 - AppWorkoutManager의 endWorkout 호출
                            workoutManager.endWorkout()
                        })
                        .environmentObject(workoutManager) // 하위 뷰에 workoutManager 전달 (필요 시)
                    }
                } else {
                    // ViewModel이 없는 경우 표시할 내용 (오류 상태 등)
                    Text("워크아웃 세션 정보를 불러올 수 없습니다.")
                }
            }

            // 워크아웃 결과 화면 모달 (새로 추가)
            .fullScreenCover(isPresented: $workoutManager.showResultView) {
                 // 결과 데이터가 있을 때만 WorkoutResultView 표시
                 if let completedSession = workoutManager.completedWorkoutSession {
                     WorkoutResultView(workoutSession: completedSession)
                         .environmentObject(workoutManager) // 결과 뷰에 Manager 전달
                 } else {
                     // 데이터가 없는 비정상적인 경우 (로딩 또는 오류 표시)
                     VStack {
                         Text("결과 데이터를 로딩 중이거나 오류가 발생했습니다.")
                         Button("닫기") {
                             workoutManager.dismissResultView()
                         }
                         .padding(.top)
                     }
                 }
             }
    }
}

struct GlobalWorkoutSessionView_Previews: PreviewProvider {
    static var previews: some View {
        // 프리뷰에서는 workoutManager 상태를 조작하여 테스트 가능
        let manager = AppWorkoutManager.shared
        // 예: 결과 화면 테스트
        // manager.completedWorkoutSession = WorkoutSessionModel(...) // 샘플 데이터 생성
        // manager.showResultView = true

        GlobalWorkoutSessionView()
            .environmentObject(manager)
    }
}

// WorkoutSessionContainerView 정의 (만약 사용하고 있다면)
struct WorkoutSessionContainerView: View {
    var body: some View {
        // 이 뷰가 다른 역할을 하지 않는다면 제거하거나 비워둘 수 있습니다.
        EmptyView()
    }
} 