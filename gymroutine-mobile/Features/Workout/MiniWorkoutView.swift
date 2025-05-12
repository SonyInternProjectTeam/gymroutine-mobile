import SwiftUI

struct MiniWorkoutView: View {
    @ObservedObject var workoutManager = AppWorkoutManager.shared
    // タイマーをリアルタイムで更新するためのトリガー
    @State private var timerTrigger = Date()
    private let analyticsService = AnalyticsService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // 上部の区切り線
            Divider()
                .padding(.bottom, 6)
            
            // ワークアウト進行状況
            HStack(spacing: 16) {
                // タイマー表示
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.2))
                        .frame(width: 45, height: 45)
                    
                    if let sessionViewModel = workoutManager.workoutSessionViewModel {
                        Text("\(sessionViewModel.minutes):\(String(format: "%02d", sessionViewModel.seconds))")
                            .font(.callout.bold())
                            .foregroundStyle(.blue)
                    }
                }
                
                // 現在のエクササイズイメージ
                if let sessionViewModel = workoutManager.workoutSessionViewModel,
                   let currentExercise = sessionViewModel.currentExercise {
                    ExerciseImageCell(imageName: currentExercise.name)
                        .frame(width: 45, height: 45)
                }
                
                // 現在のエクササイズ名と進行状況
                VStack(alignment: .leading, spacing: 3) {
                    if let sessionViewModel = workoutManager.workoutSessionViewModel,
                       let currentExercise = sessionViewModel.currentExercise {
                        Text(LocalizedStringKey(currentExercise.name))
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    
                    if let sessionViewModel = workoutManager.workoutSessionViewModel {
                        Text("\(sessionViewModel.completedSetsCountForCurrentExercise)/\(sessionViewModel.currentExerciseSetsCount) セット完了")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // コントロールボタン
                HStack(spacing: 12) {
                    // 最大化ボタン
                    Button {
                        workoutManager.maximizeWorkoutSession()
                    } label: {
                        Image(systemName: "arrow.up.right.square")
                            .font(.headline)
                            .foregroundStyle(.blue)
                            .frame(width: 38, height: 38)
                            .background(.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    // 終了ボタン
                    Button {
                        workoutManager.endWorkout()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(.red)
                            .frame(width: 38, height: 38)
                            .background(.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemBackground))
        .contentShape(Rectangle())
        .gesture(
            TapGesture()
                .onEnded { _ in
                    workoutManager.maximizeWorkoutSession()
                }
        )
        // タブバーとの境界を強調するための下部シャドウ
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
        // タイマー更新のためのイベント処理
        .onAppear {
            // 1秒ごとに画面を更新するタイマーを開始
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                timerTrigger = Date() // 状態変数を更新してビューをリフレッシュ
            }
            
            // Log screen view
            // analyticsService.logScreenView(screenName: "MiniWorkout")
        }
        // 画面が更新されるたびにtimerTriggerを更新してビューをリフレッシュ
        .id(timerTrigger)
    }
} 