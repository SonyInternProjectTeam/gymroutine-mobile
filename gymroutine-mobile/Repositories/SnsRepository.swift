//
//  SnsRepository.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/03/01.
//

import Foundation
import FirebaseFirestore

/// SNS関連のDB通信を担当するRepositoryクラス
class SnsRepository {
    private let db = Firestore.firestore()
    
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
}
