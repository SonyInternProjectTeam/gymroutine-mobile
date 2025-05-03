import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published var user: User?
    @Published var analytics: UserAnalytics?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let analyticsService = AnalyticsService.shared
    private let db = Firestore.firestore()
    private let userManager = UserManager.shared
    
    // MARK: - データロードメソッド
    
    init() {
        // UserManagerから最新ユーザー情報を取得
        loadUserData()
    }
    
    /// 現在のユーザー情報をUserManagerから読み込むメソッド
    func loadUserData() {
        self.user = userManager.currentUser
        if let user = self.user {
            print("UserManagerからユーザー情報のロード完了: \(user.name)")
        } else {
            print("UserManagerからユーザー情報が見つかりません")
        }
    }
    
    /// 現在のユーザーの運動分析データを読み込むメソッド
    func loadAnalytics() {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.error = NSError(domain: "AnalyticsViewModel", code: 1, 
                                 userInfo: [NSLocalizedDescriptionKey: "ユーザーがログインしていません。"])
            return
        }
        
        isLoading = true
        error = nil
        
        analyticsService.getUserAnalytics(userId: userId) { [weak self] (analytics, error) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error
                    print("分析データの読み込みエラー: \(error.localizedDescription)")
                } else {
                    self?.analytics = analytics
                }
            }
        }
    }
    
    /// 現在のユーザーの運動分析データを更新するメソッド
    /// - Parameter completion: 完了ハンドラ (成功状況とエラー)
    func updateAnalytics(completion: @escaping (Bool, Error?) -> Void) async {
        guard let user = Auth.auth().currentUser else {
            let error = NSError(domain: "AnalyticsViewModel", code: 1,
                                userInfo: [NSLocalizedDescriptionKey: "ユーザーがログインしていません。"])
            completion(false, error)
            return
        }
        
        // デバッグ用のログ出力
        print("ViewModel - 運動分析の更新リクエスト: ユーザーID \(user.uid)")
        print("ViewModel - ログイン情報: \(user.email ?? "メールなし"), プロバイダー: \(user.providerID)")
        
        // ユーザーIDを確実に確認
        let userId = user.uid
        print("ViewModel - 確認されたユーザーID: \(userId)")
        
        // 現在ログインしているユーザー情報の確認
        if let token = try? await user.getIDToken() {
            print("ViewModel - ユーザートークン確認済み (最初の10文字): \(String(token.prefix(10)))...")
        } else {
            print("ViewModel - ユーザートークンを取得できません")
        }
        
        isLoading = true
        error = nil
        
        // サービスメソッドの呼び出し
        analyticsService.updateUserAnalytics(userId: userId) { [weak self] (success, error) in
            Task { @MainActor in
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error
                    print("分析データの更新エラー: \(error.localizedDescription)")
                    if let nsError = error as NSError? {
                        print("エラー詳細情報: ドメイン \(nsError.domain), コード \(nsError.code), 情報 \(nsError.userInfo)")
                    }
                    completion(false, error)
                } else {
                    print("分析データの更新結果: \(success ? "成功" : "失敗")")
                    if success {
                        // 成功時に少し遅延してからデータを再読み込み
                        try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                        self?.loadAnalytics()
                        self?.loadUserData()
                    }
                    completion(success, nil)
                }
            }
        }
    }
    
    // MARK: - ユーティリティメソッド
    
    /// 運動部位別分布に応じて色を返すユーティリティメソッド
    /// - Parameter part: 運動部位名
    /// - Returns: 該当部位の色
    func colorForPart(_ part: String) -> Color {
        switch part.lowercased() {
        case "chest":
            return .red
        case "back":
            return .blue
        case "legs":
            return .green
        case "arm":
            return .orange
        case "shoulder":
            return .purple
        case "core":
            return .yellow
        default:
            return .gray
        }
    }
    
    /// 1RMデータをソートして返すメソッド
    /// - Parameter oneRepMax: 1RMデータ
    /// - Returns: 降順でソートされた1RMデータ
    func getSortedOneRepMax(from oneRepMax: OneRepMaxInfo) -> [(key: String, value: Double)] {
        return oneRepMax.sorted { $0.value > $1.value }
    }
    
    /// 部位別運動分布をチャート用データに変換するメソッド
    /// - Parameter distribution: 分布データ
    /// - Returns: チャート用データ
    func getDistributionChartData(from distribution: ExerciseDistribution) -> [(String, Double)] {
        return distribution
            .map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }
    }
    
    /// フォロー中比較結果に対する説明文字列を返すメソッド
    /// - Parameter comparison: 比較データ
    /// - Returns: 説明文字列
    func getFollowingComparisonText(from comparison: FollowingComparison) -> String {
        let diff = comparison.user - comparison.followingAvg
        
        if diff > 0 {
            return "あなたはフォロー中のユーザーより週に\(diff)回多く運動しています"
        } else if diff < 0 {
            return "あなたはフォロー中のユーザーより週に\(abs(diff))回少なく運動しています"
        } else {
            return "あなたはフォロー中のユーザーと同じくらい運動しています"
        }
    }
}
