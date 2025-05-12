import SwiftUI
import Charts
import FirebaseFirestore

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var showingUpdateAlert = false
    @State private var updateSuccess = false
    @State private var errorMessage = ""
    private let analyticsService = AnalyticsService.shared
    
    var body: some View {
            VStack(spacing: 20) {
                // 上部ヘッダー
                AnalyticsHeaderView(updatedAt: viewModel.analytics?.updatedAt.dateValue(),
                    isLoading: viewModel.isLoading,
                    updateAction: {
                        Task {
                            await viewModel.updateAnalytics { success, error in
                                updateSuccess = success
                                errorMessage = error?.localizedDescription ?? ""
                                showingUpdateAlert = true
                            }
                        }
                    }
                )
                
                if viewModel.isLoading {
                    // ローディングインジケーター
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let analytics = viewModel.analytics {
                    // データがある場合、分析コンポーネントを表示
                    VStack(spacing: 24) {
                        // 運動部位の分布
                        DistributionPieChartView(distribution: analytics.distribution)
                        
                        // 体重変化グラフ
                        WeightHistoryGraphView(userId: UserManager.shared.currentUser?.uid ?? "")
                        
                        // 運動遵守率
                        AdherenceCircleChartView(adherence: analytics.adherence)
                        
                        // お気に入り運動
                        FavoriteExercisesView(exercises: analytics.favoriteExercises)
                        
                        // フォロー中比較
                        FollowingComparisonChartView(comparison: analytics.followingComparison)
                        
                        // 1RM情報
                        OneRepMaxBarChartView(oneRepMax: analytics.oneRepMax)
                    }
                    .padding(.horizontal)
                } else {
                    // データがない場合のガイドメッセージ
                    NoAnalyticsDataView {
                        Task {
                            await viewModel.updateAnalytics { success, error in
                                updateSuccess = success
                                errorMessage = error?.localizedDescription ?? ""
                                showingUpdateAlert = true
                            }
                        }
                    }
                }
        }
        .alert(isPresented: $showingUpdateAlert) {
            Alert(
                title: Text(updateSuccess ? "分析完了" : "分析失敗"),
                message: Text(updateSuccess 
                              ? "分析データが更新されました。しばらくしてからもう一度確認してください。"
                              : "分析データの更新に失敗しました。\(errorMessage)"),
                dismissButton: .default(Text("確認")) {
                    if updateSuccess {
                        // 更新成功時、5秒後にデータを再読み込み
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            viewModel.loadAnalytics()
                        }
                    }
                }
            )
        }
        .onAppear {
            viewModel.loadAnalytics()
            viewModel.loadUserData()
            
            // Log screen view
            analyticsService.logScreenView(screenName: "Analytics")
        }
    }
}

// MARK: - 分析ヘッダービュー
struct AnalyticsHeaderView: View {
    let updatedAt: Date?
    let isLoading: Bool
    let updateAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack{
                Text("運動分析")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button(action: updateAction) {
                Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
            Text("過去90日間の運動データに基づく")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let updatedAt = updatedAt {
                Text("最終更新: \(updatedAt.formatted(.dateTime.day().month().hour().minute()))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - データなし案内ビュー
struct NoAnalyticsDataView: View {
    let updateAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("分析データがありません")
                .font(.headline)
            
            Text("運動記録が十分に蓄積されると\n分析情報が表示されます")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: updateAction) {
                Text("今すぐ分析する")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding()
    }
}

#Preview {
    NavigationView {
        AnalyticsView()
    }
}
