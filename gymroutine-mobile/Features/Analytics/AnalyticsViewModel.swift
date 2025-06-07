import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published var user: User?
    @Published var analytics: UserAnalytics?
    @Published var isLoading = false
    @Published var error: Error?
    
    // 알림 관련 상태 변수
    @Published var showingUpdateAlert = false
    @Published var updateSuccess = false
    @Published var alertMessage = ""

    private let userAnalyticsService = UserAnalyticsService.shared
    private let db = Firestore.firestore()
    private let userManager = UserManager.shared
    private let userId: String
    
    // MARK: - データロードメソッド
    
    init(userId: String) {
        self.userId = userId
    }
    
    /// 現在のユーザー情報をFirestoreから読み込むメソッド
    func loadUserData() async {
        if userId.isEmpty {
            self.error = NSError(domain: "AnalyticsViewModel", code: 1, 
                                userInfo: [NSLocalizedDescriptionKey: "ユーザーIDが指定されていません。"])
            return
        }
        
        do {
            let snapshot = try await db.collection("Users").document(userId).getDocument()
            if snapshot.exists, let data = snapshot.data() {
                let user = try Firestore.Decoder().decode(User.self, from: data)
                self.user = user
                print("Firestoreからユーザー情報のロード完了: \(user.name)")
            } else {
                print("Firestoreからユーザー情報が見つかりません")
                self.user = nil
            }
        } catch {
            print("ユーザー情報の読み込みエラー: \(error.localizedDescription)")
            self.user = nil
            self.error = error
        }
    }
    
    /// 指定されたユーザーの運動分析データを読み込むメソッド
    func loadAnalytics() {
        if userId.isEmpty {
            self.error = NSError(domain: "AnalyticsViewModel", code: 1, 
                                userInfo: [NSLocalizedDescriptionKey: "ユーザーIDが指定されていません。"])
            return
        }
        
        isLoading = true
        error = nil
        
        userAnalyticsService.getUserAnalytics(userId: userId) { [weak self] (analytics, error) in
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
    
    /// View에서 호출할 분석 요청 메소드
    func requestAnalyticsUpdate() async {
        await updateAnalytics { [weak self] success, error in
            guard let self = self else { return }
            
            self.updateSuccess = success
            self.alertMessage = getAlertMessage(error: error)
            self.showingUpdateAlert = true
        }
    }
    
    /// 現在のユーザーの運動分析データを更新するメソッド
    /// - Parameter completion: 完了ハンドラ (成功状況とエラー)
    func updateAnalytics(completion: @escaping (Bool, Error?) -> Void) async {
        if userId.isEmpty {
            let error = NSError(domain: "AnalyticsViewModel", code: 1,
                               userInfo: [NSLocalizedDescriptionKey: "ユーザーIDが指定されていません。"])
            completion(false, error)
            return
        }
        
        // 現在のユーザーとリクエスト対象ユーザーが異なる場合は権限エラー
        guard let currentUser = Auth.auth().currentUser, currentUser.uid == userId else {
            let error = NSError(domain: "AnalyticsViewModel", code: 403,
                               userInfo: [NSLocalizedDescriptionKey: "他のユーザーの分析データは更新できません。"])
            completion(false, error)
            return
        }
        
        // デバッグ用のログ出力
        print("ViewModel - 運動分析の更新リクエスト: ユーザーID \(userId)")
        
        isLoading = true
        error = nil
        
        // サービスメソッドの呼び出し
        userAnalyticsService.updateUserAnalytics(userId: userId) { [weak self] (success, error) in
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
                        Task {
                            await self?.loadUserData()
                        }
                        completion(success, nil)
                    }
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

    func getAlertTitle() -> String {
        return updateSuccess ? "分析完了" : "更新エラー"
    }

    func getAlertMessage(error: Error?) -> String {
        if updateSuccess {
            return "分析データが更新されました。しばらくしてからもう一度確認してください。"
        } else {
            if let error = error as? NSError, error.code == 1001 {
                return "運動記録がないため分析できません。"
            }
            return "分析データの更新に失敗しました。"
        }
    }
}
