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
    private let cacheExpiryHours = 24 // 캐시 유효 시간 (시간 단위)
    
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
    
    /// おすすめユーザーリストを取得するメソッド (Firestore 캐시 우선 확인)
    /// - Parameter userId: 現在ログイン中のユーザーID
    /// - Returns: 推薦ユーザーの配列またはエラーをResultで返す
    func fetchRecommendedUsers(for userId: String) async -> Result<[RecommendedUser], Error> {
        do {
            print("🔍 [SnsRepository] fetchRecommendedUsers 호출됨 - userId: \(userId)")

            // 1. Firestore 캐시 확인 (/Recommendations/{userId})
            let recommendationRef = db.collection("Recommendations").document(userId)
            let cacheDoc = try? await recommendationRef.getDocument() // 에러는 무시하고 진행

            if let cacheData = cacheDoc?.data(), cacheDoc?.exists == true {
                print("🔍 [SnsRepository] Firestore 캐시 발견 - userId: \(userId)")
                if let updatedAt = (cacheData["updatedAt"] as? Timestamp)?.dateValue(),
                   let cachedRecommendations = cacheData["recommendedUsers"] as? [[String: Any]],
                   !isCacheExpired(updatedAt: updatedAt) {

                    print("✅ [SnsRepository] 유효한 캐시 사용 - updatedAt: \(updatedAt)")
                    // 캐시 데이터 파싱 및 사용자 정보 조회
                    let recommendedUsers = await parseRecommendationsAndFetchUsers(cachedRecommendations)
                    print("✅ [SnsRepository] 캐시로부터 추천 사용자 로드 완료 - \(recommendedUsers.count)명")
                    return .success(recommendedUsers)
                } else {
                    print("⚠️ [SnsRepository] 캐시 만료 또는 데이터 형식 오류 - updatedAt: \((cacheData["updatedAt"] as? Timestamp)?.dateValue()), recommendations count: \((cacheData["recommendedUsers"] as? [[String: Any]])?.count ?? -1)")
                }
            } else {
                print("🔍 [SnsRepository] Firestore 캐시 없음 또는 읽기 실패 - userId: \(userId)")
            }

            // 2. 캐시가 없거나 만료된 경우 Firebase Function 호출
            print("☁️ [SnsRepository] Firebase Function 'getUserRecommendations' 호출 시작 - 파라미터: userId=\(userId)")
            let data: [String: Any] = ["userId": userId]
            let result = try await functions.httpsCallable("getUserRecommendations").call(data)
            print("☁️ [SnsRepository] Firebase Function 호출 완료 - 결과: \(result.data ?? "nil")")

            // 3. Function 결과 처리
            guard let functionData = result.data as? [String: Any],
                  let success = functionData["success"] as? Bool,
                  success == true,
                  // Function 결과에 recommendedUsers가 없을 수도 있음 (백엔드 로직 확인 필요)
                  // 백엔드에서 캐시된 결과를 그대로 반환할 수도 있음
                  let recommendations = functionData["recommendations"] as? [[String: Any]] ??
                                        (functionData["recommendedUsers"] as? [[String: Any]]) // 백엔드 반환값 확인 필요
            else {
                // Function 호출은 성공했으나, 백엔드 로직상 캐시를 반환했거나 데이터 형식이 다를 수 있음
                // 이 경우 백엔드에서 업데이트된 캐시를 다시 읽도록 시도할 수 있으나, 복잡도를 높임
                // 여기서는 파싱 실패로 처리
                print("⚠️ [SnsRepository] Function 결과 데이터 파싱 실패 또는 추천 데이터 없음")
                // 백엔드에서 캐시 업데이트를 보장하므로, 빈 배열 반환 또는 오류 처리
                // return .success([]) // 또는 아래 오류 반환
                 return .failure(NSError(domain: "SnsRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse recommendations from function result"]))
            }

            print("🔍 [SnsRepository] Function 결과 파싱 완료 - \(recommendations.count)개의 추천 항목")

            // Function 결과로부터 추천 사용자 정보 조회 및 반환
            // (백엔드에서 캐시 저장 후 Function이 결과를 반환하므로, 클라에서 다시 저장할 필요는 없음)
            let recommendedUsers = await parseRecommendationsAndFetchUsers(recommendations)
            print("✅ [SnsRepository] Function으로부터 추천 사용자 로드 완료 - \(recommendedUsers.count)명")
            return .success(recommendedUsers)

        } catch {
            print("⛔️ [SnsRepository] fetchRecommendedUsers 오류 - \(error.localizedDescription)")
            return .failure(error)
        }
    }

    /// 추천 목록 데이터 (Firestore 캐시 또는 Function 결과)를 파싱하고 사용자 정보를 조회하는 헬퍼 함수
    private func parseRecommendationsAndFetchUsers(_ recommendations: [[String: Any]]) async -> [RecommendedUser] {
        var recommendedUsers: [RecommendedUser] = []
        for recommendation in recommendations {
            guard let recommendedUserId = recommendation["userId"] as? String,
                  let score = recommendation["score"] as? Int else {
                print("⚠️ [SnsRepository Helper] 추천 항목 데이터 형식 오류 - 항목: \(recommendation)")
                continue
            }

            // 추천된 사용자 상세 정보 조회
            print("🔍 [SnsRepository Helper] 추천 사용자 정보 조회 - userId: \(recommendedUserId)")
            do {
                let userDoc = try await db.collection("Users").document(recommendedUserId).getDocument()
                if let userData = userDoc.data() {
                    let user = try Firestore.Decoder().decode(User.self, from: userData)
                    let recommendedUser = RecommendedUser(user: user, score: score)
                    recommendedUsers.append(recommendedUser)
                    print("✅ [SnsRepository Helper] 사용자 정보 조회 성공 - name: \(user.name ?? "N/A")")
                } else {
                    print("⚠️ [SnsRepository Helper] 사용자 정보 없음 - userId: \(recommendedUserId)")
                }
            } catch {
                 print("⛔️ [SnsRepository Helper] 사용자 정보 조회 오류 - userId: \(recommendedUserId), error: \(error.localizedDescription)")
            }
        }
        return recommendedUsers
    }

    /// 캐시 유효 기간 확인 헬퍼 함수
    private func isCacheExpired(updatedAt: Date) -> Bool {
        let now = Date()
        let timeInterval = now.timeIntervalSince(updatedAt)
        let hoursPassed = timeInterval / 3600 // 초를 시간으로 변환

        print("🔍 [SnsRepository Cache] 캐시 경과 시간: \(String(format: "%.2f", hoursPassed)) 시간")
        return hoursPassed >= Double(cacheExpiryHours)
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
