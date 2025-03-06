//
//  FollowRepository.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/03/01.
//

import Foundation
import FirebaseFirestore

/// フォロー関連のDB通信を担当するリポジトリクラス
class FollowRepository {
    private let db = Firestore.firestore()
    
    /// 指定したユーザーのフォロワー一覧を取得する
    /// - Parameter userID: 対象ユーザーのID
    /// - Returns: フォロワーのUserの配列またはエラーをResultで返す
    func fetchFollowers(for userID: String) async -> Result<[User], Error> {
        do {
            let snapshot = try await db.collection("Users")
                .document(userID)
                .collection("Followers")
                .getDocuments()
            var users: [User] = []
            for doc in snapshot.documents {
                let followerUserID = doc.documentID
                let userDoc = try await db.collection("Users").document(followerUserID).getDocument()
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
    
    /// 指定したユーザーのフォロー中一覧を取得する
    /// - Parameter userID: 対象ユーザーのID
    /// - Returns: フォロー中のUserの配列またはエラーをResultで返す
    func fetchFollowing(for userID: String) async -> Result<[User], Error> {
        do {
            let snapshot = try await db.collection("Users")
                .document(userID)
                .collection("Following")
                .getDocuments()
            var users: [User] = []
            for doc in snapshot.documents {
                let followingUserID = doc.documentID
                let userDoc = try await db.collection("Users").document(followingUserID).getDocument()
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
    
    /// フォロー操作：指定されたユーザーをフォローする
    /// - Parameters:
    ///   - currentUserID: 現在ログイン中のユーザーID
    ///   - profileUserID: フォロー対象のユーザーID
    /// - Throws: エラー発生時にスローする
    func addFollow(currentUserID: String, profileUserID: String) async throws {
        try await db.collection("Users")
            .document(currentUserID)
            .collection("Following")
            .document(profileUserID)
            .setData(["followedAt": FieldValue.serverTimestamp()])
        
        try await db.collection("Users")
            .document(profileUserID)
            .collection("Followers")
            .document(currentUserID)
            .setData(["followedAt": FieldValue.serverTimestamp()])
    }
    
    /// フォロー解除操作：指定されたユーザーのフォローを解除する
    /// - Parameters:
    ///   - currentUserID: 現在ログイン中のユーザーID
    ///   - profileUserID: フォロー解除対象のユーザーID
    /// - Throws: エラー発生時にスローする
    func removeFollow(currentUserID: String, profileUserID: String) async throws {
        try await db.collection("Users")
            .document(currentUserID)
            .collection("Following")
            .document(profileUserID)
            .delete()
        
        try await db.collection("Users")
            .document(profileUserID)
            .collection("Followers")
            .document(currentUserID)
            .delete()
    }
    
    /// フォロー状態を確認する
    /// - Parameters:
    ///   - currentUserID: 現在ログイン中のユーザーID
    ///   - profileUserID: 対象ユーザーのID
    /// - Returns: フォローしている場合 true、していない場合 false
    func checkFollowingStatus(currentUserID: String, profileUserID: String) async -> Bool {
        let doc = try? await db.collection("Users")
            .document(currentUserID)
            .collection("Following")
            .document(profileUserID)
            .getDocument()
        return doc?.exists ?? false
    }
}
