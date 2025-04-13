//
//  SnsRepository.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/03/01.
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions

/// SNS関連のDB通信を担当するRepositoryクラス
class SnsRepository {
    private let db = Firestore.firestore()
    private let functions = Functions.functions()
    
    /// 現在のユーザーがフォローしているユーザー一覧を取得する
    /// - Parameter userID: 現在ログイン中のユーザーID
    /// - Returns: フォローしているユーザーの配列またはエラーをResultで返す
    func fetchFollowingUsers(for userID: String) async -> Result<[User], Error> {
        do {
            // 現在のユーザーのFollowingコレクションからフォロー中のユーザーIDを取得する
            let snapshot = try await db.collection("Users")
                .document(userID)
                .collection("Following")
                .getDocuments()
            var users: [User] = []
            // 各フォロー中のユーザーIDに対してユーザーデータを取得する
            for doc in snapshot.documents {
                let followedUserID = doc.documentID
                let userDoc = try await db.collection("Users").document(followedUserID).getDocument()
                if let data = userDoc.data() {
                    let user = try Firestore.Decoder().decode(User.self, from: data)
                    users.append(user)
                }
            }
            return .success(users)
        } catch {
            return .failure(error)
        }
    }
    
    /// おすすめユーザーリストを取得するメソッド
    /// - Parameter userId: 現在ログイン中のユーザーID
    /// - Returns: 推薦ユーザーの配列またはエラーをResultで返す
    func fetchRecommendedUsers(for userId: String) async -> Result<[RecommendedUser], Error> {
        do {
            print("🔍 [SnsRepository] fetchRecommendedUsers 호출됨 - userId: \(userId)")
            
            // Firebase Functionsのユーザー推薦関数を呼び出す - 직접 데이터 맵 구성
            print("🔍 [SnsRepository] Firebase Function 'getUserRecommendations' 호출 시작 - 파라미터: userId=\(userId)")
            
            // userId 파라미터를 명시적으로 맵에 추가하여 전달
            let data: [String: Any] = ["userId": userId]
            
            let result = try await functions.httpsCallable("getUserRecommendations").call(data)
            print("🔍 [SnsRepository] Firebase Function 호출 완료 - 결과: \(result.data)")
            
            // レスポンスデータをパース
            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success == true,
                  let recommendations = data["recommendations"] as? [[String: Any]] else {
                print("⚠️ [SnsRepository] 응답 데이터 파싱 실패")
                return .failure(NSError(domain: "SnsRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse recommendations"]))
            }
            
            print("🔍 [SnsRepository] 추천 데이터 파싱 완료 - \(recommendations.count)개의 추천 항목")
            
            // 推薦ユーザーIDとスコアを取得
            var recommendedUsers: [RecommendedUser] = []
            for recommendation in recommendations {
                guard let recommendedUserId = recommendation["userId"] as? String,
                      let score = recommendation["score"] as? Int else {
                    print("⚠️ [SnsRepository] 추천 항목 데이터 형식 오류")
                    continue
                }
                
                // 推薦されたユーザーの詳細情報を取得
                print("🔍 [SnsRepository] 추천 사용자 정보 조회 - userId: \(recommendedUserId)")
                let userDoc = try await db.collection("Users").document(recommendedUserId).getDocument()
                if let userData = userDoc.data() {
                    let user = try Firestore.Decoder().decode(User.self, from: userData)
                    let recommendedUser = RecommendedUser(user: user, score: score)
                    recommendedUsers.append(recommendedUser)
                    print("✅ [SnsRepository] 사용자 정보 조회 성공 - name: \(user.name)")
                } else {
                    print("⚠️ [SnsRepository] 사용자 정보 없음 - userId: \(recommendedUserId)")
                }
            }
            
            print("✅ [SnsRepository] fetchRecommendedUsers 완료 - \(recommendedUsers.count)명의 추천 사용자")
            return .success(recommendedUsers)
        } catch {
            print("⛔️ [SnsRepository] fetchRecommendedUsers 오류 - \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    /// 推薦リストを強制的に更新するメソッド（必要に応じて使用、通常は不要）
    /// - Parameter userId: 現在ログイン中のユーザーID
    /// - Returns: 更新成功かどうかをResultで返す
    func forceUpdateRecommendations(for userId: String) async -> Result<Bool, Error> {
        do {
            print("🔍 [SnsRepository] forceUpdateRecommendations 호출됨 - userId: \(userId)")
            
            // userId 파라미터를 명시적으로 맵에 추가하여 전달
            let data: [String: Any] = ["userId": userId]
            
            print("🔍 [SnsRepository] Firebase Function 'forceUpdateRecommendations' 호출 시작 - 파라미터: userId=\(userId)")
            let result = try await functions.httpsCallable("forceUpdateRecommendations").call(data)
            print("🔍 [SnsRepository] Firebase Function 호출 완료 - 결과: \(result.data)")
            
            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool else {
                print("⚠️ [SnsRepository] 응답 데이터 파싱 실패")
                return .failure(NSError(domain: "SnsRepository", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse update result"]))
            }
            
            print("✅ [SnsRepository] forceUpdateRecommendations 완료 - 결과: \(success)")
            return .success(success)
        } catch {
            print("⛔️ [SnsRepository] forceUpdateRecommendations 오류 - \(error.localizedDescription)")
            return .failure(error)
        }
    }
}
