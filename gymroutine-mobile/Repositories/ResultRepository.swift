import Foundation
import FirebaseFirestore

class ResultRepository {
    private let db = Firestore.firestore()
    
    // MARK: - Fetch Operations
    
    /// 特定ユーザーの特定期間のデータを取得
    func fetchResults(userId: String, startDate: Date, endDate: Date) async throws -> [WorkoutResult] {
        // 年月形式の文字列を生成するフォーマッター
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMM"
        
        let startYearMonth = dateFormatter.string(from: startDate)
        let endYearMonth = dateFormatter.string(from: endDate)
        
        print("[DEBUG] 検索期間: \(startDate.formatted()) 〜 \(endDate.formatted())")
        print("[DEBUG] 検索対象月: \(startYearMonth) 〜 \(endYearMonth)")
        print("[DEBUG] ユーザーID: \(userId)")
        
        var results: [WorkoutResult] = []
        
        // 開始月と終了月が同じ場合
        if startYearMonth == endYearMonth {
            let monthResults = try await fetchResultsForMonth(userId: userId, yearMonth: startYearMonth)
            results.append(contentsOf: monthResults)
        } else {
            // 開始月から終了月までのすべての月のデータを取得
            var currentDate = startDate
            let endOfEndMonth = Calendar.current.date(
                from: Calendar.current.dateComponents([.year, .month], from: endDate))!
            let endOfEndMonthPlus1Month = Calendar.current.date(byAdding: .month, value: 1, to: endOfEndMonth)!
            
            while currentDate < endOfEndMonthPlus1Month {
                let currentYearMonth = dateFormatter.string(from: currentDate)
                
                do {
                    let monthResults = try await fetchResultsForMonth(userId: userId, yearMonth: currentYearMonth)
                    results.append(contentsOf: monthResults)
                } catch {
                    print("[ERROR] \(currentYearMonth)月のデータ取得に失敗: \(error)")
                }
                
                // 次の月に進む
                guard let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) else {
                    break
                }
                currentDate = nextMonth
            }
        }
        
        return results
    }
    
    /// 特定の月のデータを取得
    private func fetchResultsForMonth(userId: String, yearMonth: String) async throws -> [WorkoutResult] {
        print("[DEBUG] \(yearMonth)月のデータを検索中...")
        let monthCollection = db.collection("Result").document(userId).collection(yearMonth)
        
        let documents = try await monthCollection.getDocuments()
        print("[DEBUG] \(yearMonth)月のドキュメント数: \(documents.documents.count)")
        
        var results: [WorkoutResult] = []
        
        for document in documents.documents {
            do {
                var result = try document.data(as: WorkoutResult.self)
                result.id = document.documentID
                results.append(result)
            } catch {
                print("[ERROR] \(yearMonth)月のデータデコードに失敗: \(error)")
                print("[DEBUG] ドキュメントデータ: \(document.data())")
            }
        }
        
        return results
    }
    
    /// 特定のドキュメントを取得
    func fetchResult(userId: String, yearMonth: String, resultId: String) async throws -> WorkoutResult {
        let documentRef = db.collection("Result")
            .document(userId)
            .collection(yearMonth)
            .document(resultId)
        
        let documentSnapshot = try await documentRef.getDocument()
        
        guard documentSnapshot.exists else {
            throw NSError(
                domain: "ResultRepository",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "該当IDの運動結果が存在しません: \(resultId)"]
            )
        }
        
        var result = try documentSnapshot.data(as: WorkoutResult.self)
        result.id = documentSnapshot.documentID
        return result
    }
    
    /// IDで直接検索（月が不明な場合）
    func searchResultById(userId: String, resultId: String, date: Date) async throws -> WorkoutResult? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMM"
        let yearMonth = dateFormatter.string(from: date)
        
        print("[DEBUG] \(yearMonth)月のデータを検索中...")
        
        // コレクションの存在を確認
        let collectionRef = db.collection("Result").document(userId).collection(yearMonth)
        let docRef = collectionRef.document(resultId)
        let docSnapshot = try await docRef.getDocument()
        
        if docSnapshot.exists {
            var result = try docSnapshot.data(as: WorkoutResult.self)
            result.id = docSnapshot.documentID
            return result
        }
        
        return nil
    }
    
    // MARK: - Save Operations
    
    /// ワークアウト結果を保存
    func saveResult(userId: String, result: WorkoutResultModel) async throws -> String {
        // 月別サブコレクション用の年月を取得
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMM"
        let monthCollectionId = dateFormatter.string(from: result.createdAt.dateValue())
        
        // ドキュメント参照を作成
        let resultDocRef = db.collection("Result")
            .document(userId)
            .collection(monthCollectionId)
            .document()
        
        // データを保存
        try resultDocRef.setData(from: result)
        
        print("✅ ワークアウト結果を保存しました: \(resultDocRef.documentID)")
        return resultDocRef.documentID
    }
    
    // MARK: - Update Operations
    
    /// ワークアウト結果を更新
    func updateResult(userId: String, yearMonth: String, resultId: String, data: [String: Any]) async throws {
        let docRef = db.collection("Result")
            .document(userId)
            .collection(yearMonth)
            .document(resultId)
        
        try await docRef.updateData(data)
        print("✅ ワークアウト結果を更新しました: \(resultId)")
    }
    
    // MARK: - Delete Operations
    
    /// ワークアウト結果を削除
    func deleteResult(userId: String, yearMonth: String, resultId: String) async throws {
        let docRef = db.collection("Result")
            .document(userId)
            .collection(yearMonth)
            .document(resultId)
        
        try await docRef.delete()
        print("✅ ワークアウト結果を削除しました: \(resultId)")
    }
} 