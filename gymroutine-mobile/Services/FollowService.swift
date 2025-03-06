//
//  FollowService.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/03/01.
//

import Foundation

/// フォロー関連のビジネスロジックを担当するサービスクラス
class FollowService {
    private let repository = FollowRepository()
    
    /// フォロー状態を確認する
    /// - Parameters:
    ///   - currentUserID: 現在ログイン中のユーザーID
    ///   - profileUserID: 対象ユーザーのID
    /// - Returns: フォローしている場合 true、していない場合 false
    func checkFollowingStatus(currentUserID: String, profileUserID: String) async -> Bool {
        return await repository.checkFollowingStatus(currentUserID: currentUserID, profileUserID: profileUserID)
    }
    
    /// 指定されたユーザーをフォローする
    /// - Parameters:
    ///   - currentUserID: 現在ログイン中のユーザーID
    ///   - profileUserID: フォロー対象のユーザーID
    /// - Returns: 成功時は true、失敗時は false
    func followUser(currentUserID: String, profileUserID: String) async -> Bool {
        do {
            try await repository.addFollow(currentUserID: currentUserID, profileUserID: profileUserID)
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
    /// - Returns: 成功時は true、失敗時は false
    func unfollowUser(currentUserID: String, profileUserID: String) async -> Bool {
        do {
            try await repository.removeFollow(currentUserID: currentUserID, profileUserID: profileUserID)
            return true
        } catch {
            print("🔥 フォロー解除処理中にエラーが発生しました: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 指定されたユーザーのフォロワー一覧を取得する
    /// - Parameter userID: 対象ユーザーのID
    /// - Returns: フォロワーのUserの配列またはエラーをResultで返す
    func getFollowers(for userID: String) async -> Result<[User], Error> {
        return await repository.fetchFollowers(for: userID)
    }
    
    /// 指定されたユーザーのフォロー中一覧を取得する
    /// - Parameter userID: 対象ユーザーのID
    /// - Returns: フォロー中のUserの配列またはエラーをResultで返す
    func getFollowing(for userID: String) async -> Result<[User], Error> {
        return await repository.fetchFollowing(for: userID)
    }
}
