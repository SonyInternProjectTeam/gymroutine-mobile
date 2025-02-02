//
//  ProfileViewModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/01/02.
//

import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var followersCount: Int = 0
    @Published var followingCount: Int = 0
    
    private let userManager = UserManager.shared
    
    init() {
        loadUserData()
    }
    
    func loadUserData() {
        // UserManagerから
        if let currentUser = userManager.currentUser {
            self.user = currentUser
            loadFollowerAndFollowingCounts(userId: currentUser.uid)
        } else {
            print("UserManagerからユーザー情報を読み込めませんでした")
        }
    }
    
    private func loadFollowerAndFollowingCounts(userId: String) {
        // UserManagerから
        Task {
            let followers = await userManager.fetchFollowersCount(userId: userId)
            let following = await userManager.fetchFollowingCount(userId: userId)
            
            DispatchQueue.main.async {
                self.followersCount = followers
                self.followingCount = following
            }
        }
    }
}

