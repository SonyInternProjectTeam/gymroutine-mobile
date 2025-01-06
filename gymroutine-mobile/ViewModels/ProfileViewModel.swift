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

    private let userManager: UserManager

    init(userManager: UserManager) {
        self.userManager = userManager
        loadUserData()
    }

    func loadUserData() {
        // UserManagerから
        if let currentUser = userManager.currentUser {
            self.user = currentUser
            loadFollowerAndFollowingCounts(userId: currentUser.uid)
        } else {
            print("UserManager에서 유저 정보를 불러오지 못했습니다.")
        }
    }

    private func loadFollowerAndFollowingCounts(userId: String) {
        // UserManagerから
        Task {
            do {
                let followers = try await userManager.fetchFollowersCount(userId: userId)
                let following = try await userManager.fetchFollowingCount(userId: userId)

                DispatchQueue.main.async {
                    self.followersCount = followers
                    self.followingCount = following
                }
            } catch {
                print("Error loading follower/following counts: \(error)")
            }
        }
    }
}
