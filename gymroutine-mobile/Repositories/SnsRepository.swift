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
        print("[SnsRepository] Attempting to fetch following users for userID: \(userID)")
        do {
            // 現在のユーザーのFollowingコレクションからフォロー中のユーザーIDを取得する
            let followingSnapshot = try await db.collection("Users")
                .document(userID)
                .collection("Following")
                .getDocuments()
            
            print("[SnsRepository] Found \(followingSnapshot.documents.count) users in Following subcollection for \(userID).")
            
            var users: [User] = []
            // 各フォロー中のユーザーIDに対してユーザーデータを取得する
            for doc in followingSnapshot.documents {
                let followedUserID = doc.documentID
                print("[SnsRepository] Fetching user data for followedUserID: \(followedUserID)")
                do {
                    let userDoc = try await db.collection("Users").document(followedUserID).getDocument()
                    if userDoc.exists,
                       let data = userDoc.data() {
                        // Attempt to decode User
                        let user = try Firestore.Decoder().decode(User.self, from: data)
                        users.append(user)
                        print("  ✅ Successfully fetched and decoded user: \(user.email)")
                    } else {
                        print("  ⚠️ User document does not exist for followedUserID: \(followedUserID)")
                        // Decide how to handle missing user documents (e.g., skip, return error)
                        // For now, we'll just skip this user.
                    }
                } catch {
                    // Log errors during individual user fetch/decode
                    print("  🔥 Error fetching/decoding user data for followedUserID: \(followedUserID). Error: \(error)")
                    if let decodingError = error as? DecodingError {
                        print("     Decoding Error Details: \(decodingError)")
                    }
                    // Decide if one failed user should cause the whole function to fail.
                    // For now, let's continue fetching others but log the error.
                }
            }
            print("[SnsRepository] Successfully fetched \(users.count) following user profiles.")
            return .success(users)
        } catch {
            // Log errors related to fetching the 'Following' subcollection itself
            print("[SnsRepository] 🔥 Error fetching Following subcollection for userID: \(userID). Error: \(error)")
            return .failure(error) // Return the original error
        }
    }
}
