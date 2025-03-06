//
//  SnsService.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/03/01.
//

import Foundation

/// SNSおよびStory関連のビジネスロジックを担当するサービスクラス
class SnsService {
    private let repository = SnsRepository()
    
    /// 現在のユーザーがフォローしているユーザー一覧を取得する
    /// - Parameter userID: 現在ログイン中のユーザーID
    /// - Returns: フォローしているユーザーの配列またはエラーをResultで返す
    func getFollowingUsers(for userID: String) async -> Result<[User], Error> {
        return await repository.fetchFollowingUsers(for: userID)
    }
}

