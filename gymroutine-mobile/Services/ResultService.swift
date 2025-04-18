import Foundation
import FirebaseFirestore

class ResultService {
    private let repository = ResultRepository()
    
    /// 特定ユーザーの特定期間の運動結果を取得します。
    /// - Parameters:
    ///   - userId: ユーザーID
    ///   - startDate: 照会開始日
    ///   - endDate: 照会終了日
    /// - Returns: WorkoutResult配列またはnil（エラー発生時）
    func fetchWorkoutResults(forUser userId: String, startDate: Date, endDate: Date) async -> [WorkoutResult]? {
        do {
            let results = try await repository.fetchResults(userId: userId, startDate: startDate, endDate: endDate)
            print("[DEBUG] \(userId)さんの運動結果\(results.count)件を取得しました。")
            return results
        } catch {
            print("[ERROR] 運動結果の取得に失敗: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 特定の結果IDに対応する運動結果の詳細情報を取得します。
    /// - Parameters:
    ///   - resultId: 結果ID
    ///   - userId: ユーザーID（必須）
    ///   - yearMonth: 年月（形式: "yyyyMM"、必須）
    /// - Returns: WorkoutResultまたはnil（エラー発生時）
    func fetchWorkoutResultDetail(resultId: String, userId: String, yearMonth: String) async -> WorkoutResult? {
        do {
            return try await repository.fetchResult(userId: userId, yearMonth: yearMonth, resultId: resultId)
        } catch {
            print("[ERROR] 運動結果の詳細取得に失敗: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// CalendarViewで使用する簡略版
    /// resultIdのみで結果を探す場合、すべてのサブコレクションを検索します。
    /// 注意：パフォーマンスの問題があるため、可能であれば上記のメソッドの使用を推奨
    func fetchWorkoutResultDetail(resultId: String) async -> WorkoutResult? {
        print("[DEBUG] resultIdのみでの照会: \(resultId)")
        
        // 現在ログインしているユーザーIDを取得
        guard let userId = await UserManager.shared.currentUser?.uid else {
            print("[ERROR] ログインユーザーIDが取得できません")
            return nil
        }
        
        print("[DEBUG] ログインユーザーID: \(userId)")
        
        // 現在の年月を取得
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMM"
        let currentYearMonth = dateFormatter.string(from: Date())
        
        print("[DEBUG] 現在の年月: \(currentYearMonth)")
        
        // 最初に現在の年月で検索
        do {
            return try await repository.fetchResult(userId: userId, yearMonth: currentYearMonth, resultId: resultId)
        } catch {
            // 現在の月で見つからない場合は過去6ヶ月分を検索
            return await searchInPastMonths(resultId: resultId, userId: userId)
        }
    }
    
    // 過去の月のデータを検索するヘルパーメソッド
    private func searchInPastMonths(resultId: String, userId: String) async -> WorkoutResult? {
        let calendar = Calendar.current
        
        for i in 1...6 {
            if let prevDate = calendar.date(byAdding: .month, value: -i, to: Date()) {
                do {
                    if let result = try await repository.searchResultById(userId: userId, resultId: resultId, date: prevDate) {
                        print("[DEBUG] \(i)ヶ月前のデータで結果を発見しました")
                        return result
                    }
                } catch {
                    print("[ERROR] \(i)ヶ月前のデータ検索に失敗: \(error)")
                }
            }
        }
        
        print("[WARNING] 結果が見つかりませんでした: \(resultId)")
        return nil
    }
    
    /// ワークアウト結果を保存
    func saveWorkoutResult(userId: String, result: WorkoutResultModel) async -> Result<String, Error> {
        do {
            let docId = try await repository.saveResult(userId: userId, result: result)
            return .success(docId)
        } catch {
            print("[ERROR] ワークアウト結果の保存に失敗: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    /// ワークアウト結果を更新
    func updateWorkoutResult(userId: String, yearMonth: String, resultId: String, data: [String: Any]) async -> Result<Void, Error> {
        do {
            try await repository.updateResult(userId: userId, yearMonth: yearMonth, resultId: resultId, data: data)
            return .success(())
        } catch {
            print("[ERROR] ワークアウト結果の更新に失敗: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    /// ワークアウト結果を削除
    func deleteWorkoutResult(userId: String, yearMonth: String, resultId: String) async -> Result<Void, Error> {
        do {
            try await repository.deleteResult(userId: userId, yearMonth: yearMonth, resultId: resultId)
            return .success(())
        } catch {
            print("[ERROR] ワークアウト結果の削除に失敗: \(error.localizedDescription)")
            return .failure(error)
        }
    }
} 
