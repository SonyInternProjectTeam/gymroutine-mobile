import Foundation
import FirebaseFirestore
import FirebaseFunctions
import FirebaseAuth

class UserAnalyticsService {
    // シングルトンインスタンス
    static let shared = UserAnalyticsService()
    
    private let db = Firestore.firestore()
    // リージョン指定（例: "asia-northeast1"）- 実際のプロジェクトリージョンに合わせて修正
    private let functions = Functions.functions(region: "asia-northeast1")
    
    private init() {}
    
    // MARK: - データ照会メソッド
    
    /// ユーザーの運動分析データを取得するメソッド
    /// - Parameters:
    ///   - userId: ユーザーID
    ///   - completion: 完了ハンドラー（分析データとエラー）
    func getUserAnalytics(userId: String, completion: @escaping (UserAnalytics?, Error?) -> Void) {
        let docRef = db.collection("UserAnalytics").document(userId)
        
        docRef.getDocument { (document, error) in
            if let error = error {
                print("Error getting analytics: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let document = document, document.exists else {
                print("No analytics data exists for user: \(userId)")
                completion(nil, nil) // エラーなしで分析データがない場合
                return
            }
            
            do {
                let analytics = try document.data(as: UserAnalytics.self)
                completion(analytics, nil)
            } catch {
                print("Error decoding analytics data: \(error.localizedDescription)")
                completion(nil, error)
            }
        }
    }
    
    // MARK: - データ更新メソッド
    
    /// ユーザーの運動分析データを手動で更新要請するメソッド
    /// - Parameters:
    ///   - userId: ユーザーID
    ///   - completion: 完了ハンドラー（成功可否とエラー）
    func updateUserAnalytics(userId: String, completion: @escaping (Bool, Error?) -> Void) {
        print("Analytics update requested for user ID: \(userId)")
        
        // 現在認証されたユーザーを確認
        guard let currentUser = Auth.auth().currentUser else {
            let error = NSError(domain: "AnalyticsService", code: 401, 
                                userInfo: [NSLocalizedDescriptionKey: "認証されたユーザーがいません。"])
            completion(false, error)
            return
        }
        
        // バックエンド関数呼び出しのためのデータ準備
        let data: [String: Any] = ["userId": userId]
        
        // 関数名とリージョン確認
        let functionName = "updateUserAnalytics"
        let regionName = "asia-northeast1"
        print("Calling function \(functionName) in region \(regionName)")
        
        // デバッグのための関数呼び出し前データ出力
        print("Sending data to function: \(data)")
        
        // Firebase認証トークン設定
        let functions = Functions.functions(region: regionName)
        
        // Firebase Functions呼び出し
        functions.httpsCallable(functionName).call(data) { [weak self] result, error in
            if let error = error {
                print("Function call error: \(error)")
                if let nsError = error as NSError? {
                    print("Function call error details: \(nsError.domain), \(nsError.code), \(nsError.userInfo)")
                }
                completion(false, error)
                return
            }
            
            if let resultData = result?.data as? [String: Any] {
                print("Function response: \(resultData)")
                
                // successキーがある場合は使用、ない場合やBool値でない場合はfalseを返す
                if let success = resultData["success"] as? Bool {
                    completion(success, nil)
                } else {
                    print("Success key not found in response or not a boolean")
                    completion(false, nil)
                }
            } else {
                print("Unexpected response format. Raw result: \(String(describing: result?.data))")
                completion(false, NSError(domain: "AnalyticsService", code: 500, 
                                        userInfo: [NSLocalizedDescriptionKey: "サーバーレスポンスの形式が正しくありません。"]))
            }
        }
    }
    
    // MARK: - データ変換ユーティリティメソッド
    
    /// 運動部位分布データをチャートデータフォーマットに変換するメソッド
    /// - Parameter distribution: 部位別分布辞書
    /// - Returns: チャート用データ配列
    func getDistributionChartData(from distribution: ExerciseDistribution) -> [(String, Double)] {
        return distribution.map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 } // 分布率が高い順に並び替え
    }
    
    /// お気に入り運動で重量が最も高いトップN運動情報を返すメソッド
    /// - Parameter favoriteExercises: お気に入り運動リスト
    /// - Parameter count: 返す運動数
    /// - Returns: 重量基準でソートされた運動リスト
    func getTopExercisesByWeight(from favoriteExercises: [FavoriteExercise], count: Int = 3) -> [FavoriteExercise] {
        return favoriteExercises
            .sorted { $0.avgWeight > $1.avgWeight }
            .prefix(count)
            .map { $0 }
    }
    
    /// フォロー中ユーザー対比運動頻度比較文字列を返すメソッド
    /// - Parameter comparison: フォロー比較データ
    /// - Returns: 比較結果文字列
    func getFollowingComparisonString(from comparison: FollowingComparison) -> String {
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