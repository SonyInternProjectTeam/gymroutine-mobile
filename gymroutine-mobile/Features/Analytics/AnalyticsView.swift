import SwiftUI
import Charts
import FirebaseFirestore

struct AnalyticsView: View {
    @StateObject private var viewModel: AnalyticsViewModel
    @State private var heatmapData: [Date: Int] = [:]
    private let analyticsService = AnalyticsService.shared
    private let heatmapService = HeatmapService()
    private let userId: String
    private let isCurrentUser: Bool
    
    init(profileOwnerId: String? = nil) {
        let loggedInUserId = UserManager.shared.currentUser?.uid
        
        print("[AnalyticsView init] profileOwnerId (param): \(profileOwnerId ?? "nil"), loggedInUserId: \(loggedInUserId ?? "nil")")

        let targetUserId = profileOwnerId ?? loggedInUserId ?? ""
        print("[AnalyticsView init] targetUserId for ViewModel & self.userId: \(targetUserId)")

        self.userId = targetUserId
        
        self.isCurrentUser = (profileOwnerId == nil) || (profileOwnerId == loggedInUserId)
        print("[AnalyticsView init] self.isCurrentUser: \(self.isCurrentUser)")
        
        self._viewModel = StateObject(wrappedValue: AnalyticsViewModel(userId: targetUserId))
    }
    
    var body: some View {
            VStack(spacing: 12) {
                // 上部ヘッダー
                AnalyticsHeaderView(
                    updatedAt: viewModel.analytics?.updatedAt.dateValue(),
                    isLoading: viewModel.isLoading,
                    isCurrentUser: isCurrentUser,
                    updateAction: {
                        Task {
                            await viewModel.requestAnalyticsUpdate()
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
                    VStack(spacing: 12) {
                        // 運動部位の分布 - Always show for all users
                        DistributionPieChartView(distribution: analytics.distribution)
                        
                        // 体重変化グラフは現在のユーザーにのみ表示
                        if isCurrentUser {
                            // 体重変化グラフ
                            WeightHistoryGraphView(userId: userId)
                        }
                        
                        // 運動履歴ヒートマップ - Other users only
                        if !isCurrentUser {
                            HeatmapCalendarView(
                                heatmapData: heatmapData, 
                                startDate: Date(), 
                                numberOfMonths: 2, 
                                isCompactMode: true
                            )
                            .padding(.bottom, 16)
                        }
                        
                        // 運動遵守率 - Always show for all users
                        AdherenceCircleChartView(adherence: analytics.adherence)
                        
                        if isCurrentUser {
                            // お気に入り運動 - Current user only
                            FavoriteExercisesView(exercises: analytics.favoriteExercises)
                            
                            // フォロー中比較 - Current user only
                            // TODO: フォロー中比較のデータがないため、一旦コメントアウト
                            // FollowingComparisonChartView(comparison: analytics.followingComparison)
                            
                            // 1RM情報 - Current user only
                            OneRepMaxBarChartView(oneRepMax: analytics.oneRepMax)
                        }
                    }
                    .padding(.horizontal, 8)
                } else {
                    // データがない場合のガイドメッセージ
                    NoAnalyticsDataView(isCurrentUser: isCurrentUser) {
                        if isCurrentUser {
                            Task {
                                await viewModel.requestAnalyticsUpdate()
                            }
                        }
                    }
                }
        }
        .alert(isPresented: $viewModel.showingUpdateAlert) {
            Alert(
                title: Text(viewModel.updateSuccess ? "分析完了" : "分析失敗"),
                message: Text(viewModel.updateSuccess 
                              ? "分析データが更新されました。しばらくしてからもう一度確認してください。"
                              : "分析データの更新に失敗しました。\(viewModel.errorMessage)"),
                dismissButton: .default(Text("確認")) {
                    if viewModel.updateSuccess {
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
            
            // Load heatmap data for the user
            Task {
                heatmapData = await heatmapService.getMonthlyHeatmapData(for: userId)
            }
            
            // Log screen view
            analyticsService.logScreenView(screenName: "Analytics")
        }
    }
}

// MARK: - 分析ヘッダービュー
struct AnalyticsHeaderView: View {
    let updatedAt: Date?
    let isLoading: Bool
    let isCurrentUser: Bool
    let updateAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack{
                Text("運動分析")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                if isCurrentUser {
                    Button(action: updateAction) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
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
        .padding(.horizontal, 8)
        .padding(.top, 1)
    }
}

// MARK: - データなし案内ビュー
struct NoAnalyticsDataView: View {
    let isCurrentUser: Bool
    let updateAction: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("分析データがありません")
                .font(.headline)
            
            Text("運動記録が十分に蓄積されると\n分析情報が表示されます")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if isCurrentUser {
                Button(action: updateAction) {
                    Text("今すぐ分析する")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(12)
    }
}

#Preview {
    NavigationView {
        AnalyticsView()
    }
}
