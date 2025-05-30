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
    
    /// Firestoreから特定のユーザーIDのユーザー情報を取得する
    /// - Parameter userId: 取得するユーザーのID
    /// - Returns: ユーザー情報またはエラーをResultで返す
    func getUser(userId: String) async -> Result<User, Error> {
        do {
            let documentSnapshot = try await db.collection("Users").document(userId).getDocument()
            
            // Explicitly define the type here to help the compiler
            let optionalUser: User? = try documentSnapshot.data(as: User.self)
            
            guard let user = optionalUser else {
                 return .failure(NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User document with ID \\(userId) not found or failed to decode."]))
            }
            return .success(user)
        } catch {
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

    /// ユーザー設定をFireStoreのユーザープロフィールを更新する処理
    /// - Parameters:
    ///     - `userID`: ユーザーID
    ///     - `newName`: ユーザー名
    ///     - `newVisibility`: 公開範囲
    ///     - `newBirthday`: 誕生日（nilの場合は削除）
    ///     - `shouldDeleteBirthday`: 誕生日を削除するかどうか
    ///     - `hasAgreedToTerms`: 利用規約同意状態
    /// - Returns: 更新成功時はtrue、失敗時はfalseを返す
    func updateUserProfile(userID: String, newVisibility: Int?, newName: String?, newBirthday: Date? = nil, shouldDeleteBirthday: Bool = false, hasAgreedToTerms: Bool? = nil) async -> Bool {
        
        var newprofileData: [String: Any] = [:]
        
        // Build updates dictionary
        var updates: [String: Any] = [:]
        
        if let newVisibility = newVisibility {
            updates["visibility"] = newVisibility
        }
        
        if let newName = newName {
            updates["name"] = newName
        }
        
        // Handle birthday update or deletion
        if shouldDeleteBirthday {
            updates["birthday"] = FieldValue.delete()
        } else if let newBirthday = newBirthday {
            updates["birthday"] = newBirthday
        }
        
        // Handle terms agreement update
        if let hasAgreedToTerms = hasAgreedToTerms {
            updates["hasAgreedToTerms"] = hasAgreedToTerms
        }
        
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
            print("更新時にエラーが発生しました: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Updates the user's current weight and updates/adds an entry for the current day in the weight history.
    /// - Parameters:
    ///   - userId: The ID of the user to update.
    ///   - newWeight: The new weight value (in kg).
    /// - Returns: A Result indicating success or failure.
    func updateWeight(userId: String, newWeight: Double) async -> Result<Void, Error> {
        // Use the new WeightHistoryService instead
        return await WeightHistoryService.shared.updateWeight(userId: userId, newWeight: newWeight)
    }
    
    /// ユーザーをブロックする
    /// - Parameters:
    ///   - currentUserID: 現在ログイン中のユーザーID
    ///   - blockedUserID: ブロック対象のユーザーID
    /// - Throws: ブロック処理中にエラーが発生した場合
    func blockUser(currentUserID: String, blockedUserID: String) async throws {
        do {
            // 現在のユーザーの Blocked コレクションに対象ユーザーを追加
            try await db.collection("Users")
                .document(currentUserID)
                .collection("Blocked")
                .document(blockedUserID)
                .setData([
                    "blockedAt": FieldValue.serverTimestamp(),
                    "reason": "User initiated block"
                ])
            
            // フォロー関係がある場合は解除
            let isFollowing = await checkFollowingStatus(currentUserID: currentUserID, profileUserID: blockedUserID)
            if isFollowing {
                _ = await unfollowUser(currentUserID: currentUserID, profileUserID: blockedUserID)
            }
            
            print("✅ ユーザー \(blockedUserID) をブロックしました")
        } catch {
            print("🔥 ユーザーのブロック中にエラーが発生しました: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// ユーザーを警告する
    /// - Parameters:
    ///   - currentUserID: 現在ログイン中のユーザーID
    ///   - reportedUserID: 警告対象のユーザーID
    /// - Throws: 警告処理中にエラーが発生した場合
    func reportUser(currentUserID: String, reportedUserID: String) async throws {
        do {
            // 警告を Reports コレクションに追加
            try await db.collection("Reports")
                .addDocument(data: [
                    "reporterID": currentUserID,
                    "reportedUserID": reportedUserID,
                    "reportedAt": FieldValue.serverTimestamp(),
                    // TODO: 警告のステータス　後ほど修正
                    "status": "pending",
                    // TODO: 警告の種類　後ほど修正
                    "type": "user"
                ])
            
            print("✅ ユーザー \(reportedUserID) を警告しました")
        } catch {
            print("🔥 ユーザーの警告中にエラーが発生しました: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// コンテンツを報告する
    /// - Parameters:
    ///   - contentId: 報告するコンテンツのID
    ///   - contentType: コンテンツの種類 ("workout", "story", "comment", "user")
    ///   - reportedUserId: 報告対象のユーザーID
    ///   - reportType: 報告の種類
    ///   - details: 追加の詳細（任意）
    /// - Throws: 報告処理中にエラーが発生した場合
    func reportContent(
        contentId: String,
        contentType: String,
        reportedUserId: String,
        reportType: String,
        details: String? = nil
    ) async throws {
        guard let currentUserID = UserManager.shared.currentUser?.uid else {
            throw NSError(domain: "ReportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Current user not found"])
        }
        
        do {
            var reportData: [String: Any] = [
                "reporterID": currentUserID,
                "contentId": contentId,
                "contentType": contentType,
                "reportedUserId": reportedUserId,
                "reportType": reportType,
                "reportedAt": FieldValue.serverTimestamp(),
                "status": "pending"
            ]
            
            if let details = details, !details.isEmpty {
                reportData["details"] = details
            }
            
            try await db.collection("ContentReports").addDocument(data: reportData)
            
            print("✅ コンテンツ \(contentId) を報告しました")
        } catch {
            print("🔥 コンテンツの報告中にエラーが発生しました: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// ユーザーがブロックされているか確認する
    /// - Parameters:
    ///   - currentUserID: 現在ログイン中のユーザーID
    ///   - targetUserID: 確認対象のユーザーID
    /// - Returns: ブロックされている場合 true、されていない場合 false
    func isUserBlocked(currentUserID: String, targetUserID: String) async -> Bool {
        do {
            let doc = try await db.collection("Users")
                .document(currentUserID)
                .collection("Blocked")
                .document(targetUserID)
                .getDocument()
            
            return doc.exists
        } catch {
            print("🔥 ブロック状態の確認中にエラーが発生しました: \(error.localizedDescription)")
            return false
        }
    }
    
    /// ユーザーのブロックを解除する
    /// - Parameters:
    ///   - currentUserID: 現在ログイン中のユーザーID
    ///   - blockedUserID: ブロック解除対象のユーザーID
    /// - Throws: ブロック解除処理中にエラーが発生した場合
    func unblockUser(currentUserID: String, blockedUserID: String) async throws {
        do {
            // 現在のユーザーの Blocked コレクションから対象ユーザーを削除
            try await db.collection("Users")
                .document(currentUserID)
                .collection("Blocked")
                .document(blockedUserID)
                .delete()
            
            print("✅ ユーザー \(blockedUserID) のブロックを解除しました")
        } catch {
            print("🔥 ユーザーのブロック解除中にエラーが発生しました: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 現在のユーザーの利用規約同意状態を更新する
    /// - Returns: 更新成功時はtrue、失敗時はfalseを返す
    func updateTermsAgreement() async -> Bool {
        guard let currentUserID = UserManager.shared.currentUser?.uid else {
            print("🔥 Current user not found")
            return false
        }
        
        return await updateUserProfile(
            userID: currentUserID,
            newVisibility: nil,
            newName: nil,
            hasAgreedToTerms: true
        )
    }
}
