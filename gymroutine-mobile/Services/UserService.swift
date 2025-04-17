//
//  UserService.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/01/02.
//

import Foundation
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth
import UIKit

@MainActor
final class UserService {
    static let shared = UserService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    /// Firestoreから全てのユーザーを取得する
    /// - Returns: ユーザーの配列またはエラーをResultで返す
    func getAllUsers() async -> Result<[User], Error> {
        do {
            let querySnapshot = try await db.collection("Users").getDocuments()
            let users = try querySnapshot.documents.compactMap { document in
                try document.data(as: User.self)
            }
            return .success(users)
        } catch {
            return .failure(error)
        }
    }
    /// ユーザー名で検索を行う
    /// - Parameter name: 検索対象の名前
    /// - Returns: 名前に部分一致するユーザーの配列またはエラーをResultで返す
    func searchUsersByName(name: String) async -> Result<[User], Error> {
        let result = await getAllUsers()
        switch result {
        case .success(let users):
            let filteredUsers = users.filter { $0.name.contains(name) }
            return .success(filteredUsers)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// プロフィール写真をアップロードし、Firestoreのユーザードキュメントを更新する処理
    /// - Parameters:
    ///   - userID: ユーザーID
    ///   - image: アップロードするUIImage
    /// - Returns: アップロード成功時はダウンロードURL、失敗時はnilを返す
    func uploadProfilePhoto(userID: String, image: UIImage) async -> String? {
        let storageRef = storage.reference().child("profile_photos/\(userID).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.3) else { return nil }
        
        do {
            _ = try await storageRef.putDataAsync(imageData, metadata: nil)
            let downloadURL = try await storageRef.downloadURL()
            
            try await db.collection("Users").document(userID).updateData([
                "profilePhoto": downloadURL.absoluteString
            ])
            
            print("✅ プロフィール写真の更新に成功しました！")
            return downloadURL.absoluteString
        } catch {
            print("🔥 プロフィール写真のアップロード中にエラーが発生しました: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// ユーザー設定をFireStoreのユーザープロフィールを更新する処理
    /// - Parameters:
    ///     - `userID`: ユーザーID
    ///     - `user`:ユーザー名
    ///     - `newVisibility`:公開範囲
    /// - Returns: 更新成功時はtrue、失敗時はfalseを返す
    func updateUserProfile(userID: String, newVisibility: Int?, newName: String?) async -> Bool {
        
        var newprofileData: [String: Any] = [:]
        
        //nilを除外した配列を作成
        let updates: [String: Any] = [
            "visibility": newVisibility,
            "name": newName
        ].compactMapValues { $0 }
        
        if updates.isEmpty {
            print("更新データが空のため、処理をスキップします。")
            return false
        }

        newprofileData.merge(updates) { _, new in new }
        
        do {
            try await db.collection("Users").document(userID).updateData(newprofileData)
            print("ユーザードキュメントの更新に成功しました。")
            return true
        } catch {
            print("更新時にエラーが発生しました。")
            return false
        }
    }
            
    
    // MARK: - フォロー関連のFirebase通信処理
    
    /// フォロー状態を確認する
    /// - Parameters:
    ///   - currentUserID: 現在ログイン中のユーザーID
    ///   - profileUserID: 対象プロフィールのユーザーID
    /// - Returns: フォローしている場合 true、していない場合 false
    func checkFollowingStatus(currentUserID: String, profileUserID: String) async -> Bool {
        let doc = try? await db.collection("Users")
            .document(currentUserID)
            .collection("Following")
            .document(profileUserID)
            .getDocument()
        return doc?.exists ?? false
    }
    
    /// 指定されたユーザーをフォローする
    /// - Parameters:
    ///   - currentUserID: 現在ログイン中のユーザーID
    ///   - profileUserID: フォロー対象のユーザーID
    /// - Returns: 処理成功時は true、失敗時は false
    func followUser(currentUserID: String, profileUserID: String) async -> Bool {
        do {
            // 現在のユーザーの Following コレクションに対象ユーザーを追加
            try await db.collection("Users")
                .document(currentUserID)
                .collection("Following")
                .document(profileUserID)
                .setData(["followedAt": FieldValue.serverTimestamp()])
            
            // 対象ユーザーの Followers コレクションに現在のユーザーを追加
            try await db.collection("Users")
                .document(profileUserID)
                .collection("Followers")
                .document(currentUserID)
                .setData(["followedAt": FieldValue.serverTimestamp()])
            
            return true
        } catch {
            print("🔥 フォロー処理中にエラーが発生しました: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 指定されたユーザーのフォローを解除する
    /// - Parameters:
    ///   - currentUserID: 現在ログイン中のユーザーID
    ///   - profileUserID: フォロー解除対象のユーザーID
    /// - Returns: 処理成功時は true、失敗時は false
    func unfollowUser(currentUserID: String, profileUserID: String) async -> Bool {
        do {
            // 現在のユーザーの Following コレクションから対象ユーザーを削除
            try await db.collection("Users")
                .document(currentUserID)
                .collection("Following")
                .document(profileUserID)
                .delete()
            
            // 対象ユーザーの Followers コレクションから現在のユーザーを削除
            try await db.collection("Users")
                .document(profileUserID)
                .collection("Followers")
                .document(currentUserID)
                .delete()
            
            return true
        } catch {
            print("🔥 フォロー解除処理中にエラーが発生しました: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Updates the user's current weight and updates/adds an entry for the current day in the weight history.
    /// - Parameters:
    ///   - userId: The ID of the user to update.
    ///   - newWeight: The new weight value (in kg).
    /// - Returns: A Result indicating success or failure.
    func updateWeight(userId: String, newWeight: Double) async -> Result<Void, Error> {
        let userRef = db.collection("Users").document(userId)

        // Get today's date string in JST (YYYY-MM-DD)
        // Important: Use a consistent timezone (like JST) for date comparison
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo") // Set timezone to JST
        let todayDateString = dateFormatter.string(from: Date())

        do {
            // Use a transaction to read, modify, and write atomically
            try await db.runTransaction { (transaction, errorPointer) -> Any? in
                let userDocument: DocumentSnapshot
                do {
                    // Get the latest user data within the transaction
                    try userDocument = transaction.getDocument(userRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil // Signal failure
                }

                // Decode existing weight history (or default to empty array)
                var currentHistory = userDocument.data()?["WeightHistory"] as? [[String: Any]] ?? []

                // Find if an entry for today already exists
                var updated = false
                for i in 0..<currentHistory.count {
                    if let entryTimestamp = currentHistory[i]["date"] as? Timestamp {
                        let entryDateString = dateFormatter.string(from: entryTimestamp.dateValue())
                        if entryDateString == todayDateString {
                            // Update existing entry for today
                            currentHistory[i]["weight"] = newWeight
                            // Optionally update the timestamp if you want the latest update time for the day
                            // currentHistory[i]["date"] = Timestamp(date: Date())
                            updated = true
                            print("[UserService Tx] Updated existing weight entry for \(todayDateString)")
                            break
                        }
                    }
                }

                // If no entry for today was found, add a new one
                if !updated {
                    let newEntry: [String: Any] = [
                        "weight": newWeight,
                        "date": Timestamp(date: Date()) // Client-side timestamp for today (JST)
                    ]
                    currentHistory.append(newEntry)
                    print("[UserService Tx] Added new weight entry for \(todayDateString)")
                }

                // Prepare the final update data
                let updateData: [String: Any] = [
                    "currentWeight": newWeight,
                    "weightHistory": currentHistory // Write the modified array back
                ]

                // Update the document within the transaction
                transaction.updateData(updateData, forDocument: userRef)
                print("[UserService Tx] Transaction update prepared.")
                return nil // Signal success
            }

            // Transaction successful
            print("[UserService] Successfully updated weight and history for user \(userId) to \(newWeight) kg")

            // Optional: Update local UserManager's currentUser if needed immediately
            // Requires careful merging or re-fetching as the entire history array might change
            await UserManager.shared.fetchInitialUserData(userId: userId) // Re-fetch user data to get the latest state

            return .success(())

        } catch {
            // Transaction failed
            print("[UserService] Failed to update weight with transaction for user \(userId): \(error.localizedDescription)")
            return .failure(error)
        }
    }
}
