//
//  RecommendedUser.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/04/15.
//

import Foundation

/// 推薦ユーザーモデル - 推薦スコア情報を含む
struct RecommendedUser: Identifiable {
    /// 基本ユーザー情報
    let user: User
    /// 推薦スコア（0-100）
    let score: Int
    
    /// ユーザーIDをIdentifiableプロトコル対応のために返す
    var id: String {
        return user.id
    }
    
    /// スコアに基づいた推薦理由を取得する
    var recommendationReason: String {
        if score >= 80 {
            return "運動スタイルと友達ネットワークが非常に似ています"
        } else if score >= 60 {
            return "似た運動習慣を持っています"
        } else if score >= 40 {
            return "共通の友達がいます"
        } else {
            return "アクティブなユーザーです"
        }
    }
    
    /// 推薦スコアに基づいた表示用のパーセンテージを返す（UI表示用）
    var matchPercentage: Int {
        return min(max(score, 10), 99) // 最小10%、最大99%で表示
    }
}
