//
//  SnsService.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/03/01.
//

import Foundation
import gymroutine_mobile

/// SNSおよびStory関連のビジネスロジックを担当するサービスクラス
class SnsService {
    private let repository = SnsRepository()
    
    /// 現在のユーザーがフォローしているユーザー一覧を取得する
    /// - Parameter userID: 現在ログイン中のユーザーID
    /// - Returns: フォローしているユーザーの配列またはエラーをResultで返す
    func getFollowingUsers(for userID: String) async -> Result<[User], Error> {
        return await repository.fetchFollowingUsers(for: userID)
    }
    
    /// 現在のユーザーへのおすすめユーザーリストを取得する
    /// - Parameter userId: 現在ログイン中のユーザーID
    /// - Returns: 推薦ユーザーの配列またはエラーをResultで返す
    func getRecommendedUsers(for userId: String) async -> Result<[RecommendedUser], Error> {
        print("📣 [SnsService] getRecommendedUsers が呼び出されました - userId: \(userId)")
        let result = await repository.fetchRecommendedUsers(for: userId)
        
        switch result {
        case .success(let users):
            print("📣 [SnsService] getRecommendedUsers 成功 - \(users.count)人のおすすめユーザー")
        case .failure(let error):
            print("📣 [SnsService] getRecommendedUsers 失敗 - \(error.localizedDescription)")
        }
        
        return result
    }
    
    /// 推薦リストを強制的に更新する（デバッグや特定のアクションに応じて使用）
    /// - Parameter userId: 現在ログイン中のユーザーID
    /// - Returns: 更新成功かどうかをResultで返す
    func refreshRecommendations(for userId: String) async -> Result<Bool, Error> {
        print("📣 [SnsService] refreshRecommendations が呼び出されました - userId: \(userId)")
        let result = await repository.forceUpdateRecommendations(for: userId)
        
        switch result {
        case .success(let success):
            print("📣 [SnsService] refreshRecommendations 成功 - \(success)")
        case .failure(let error):
            print("📣 [SnsService] refreshRecommendations 失敗 - \(error.localizedDescription)")
        }
        
        return result
    }
}

