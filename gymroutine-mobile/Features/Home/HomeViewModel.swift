//
//  HomeViewModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/03/01.
//

import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var followingUsers: [User] = []
    
    private let snsService = SnsService()
    
    init() {
        loadFollowingUsers()
    }
    
    
    /// 現在のユーザーがフォローしているユーザー一覧を読み込む
    func loadFollowingUsers() {
        Task {
            UIApplication.showLoading()
            // UserManagerはグローバルなシングルトンとして現在のユーザー情報を管理している前提
            guard let currentUserID = UserManager.shared.currentUser?.uid else { return }
            let result = await snsService.getFollowingUsers(for: currentUserID)
            switch result {
            case .success(let users):
                self.followingUsers = users
            case .failure(let error):
                print("팔로잉ユーザーの読み込みに失敗しました: \(error.localizedDescription)")
            }
            UIApplication.hideLoading()
        }
    }
}
