//
//  ProfileViewModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/01/02.
//

import Foundation
import PhotosUI
import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var followersCount: Int = 0
    @Published var followingCount: Int = 0
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var isFollowing: Bool = false  // 現在ログイン中のユーザーがこのプロフィールをフォローしているかどうか
    
    private let userManager = UserManager.shared
    private let userService = UserService()
    
    /// プロフィールビューモデル生成時に表示するユーザーを渡すことができます。
    /// ユーザーが渡されない場合は、現在ログインしているユーザーの情報を使用します。
    init(user: User? = nil) {
        if let user = user {
            self.user = user
            loadFollowerAndFollowingCounts(userId: user.uid)
            // 自分のプロフィールでない場合、フォロー状態を確認
            if !isCurrentUser {
                checkFollowingStatus()
            }
        } else {
            loadUserData()
        }
    }
    
    /// 現在のプロフィールがログイン中のユーザーのものかどうかを判定
    var isCurrentUser: Bool {
        if let user = user, let currentUser = userManager.currentUser {
            return user.uid == currentUser.uid
        }
        return false
    }
    
    /// ログイン中のユーザー情報を読み込む
    func loadUserData() {
        if let currentUser = userManager.currentUser {
            self.user = currentUser
            loadFollowerAndFollowingCounts(userId: currentUser.uid)
        } else {
            print("UserManagerからユーザー情報を読み込めませんでした")
        }
    }
    
    /// フォロワーとフォロー中の数を読み込む
    /// - Parameter userId: ユーザーのUID
    private func loadFollowerAndFollowingCounts(userId: String) {
        Task {
            let followers = await userManager.fetchFollowersCount(userId: userId)
            let following = await userManager.fetchFollowingCount(userId: userId)
            DispatchQueue.main.async {
                self.followersCount = followers
                self.followingCount = following
            }
        }
    }
    
    /// プロフィール写真をアップロードする処理
    /// - Parameter image: アップロードするUIImage
    func uploadProfilePhoto(_ image: UIImage) {
        Task {
            guard let userID = userManager.currentUser?.uid else { return }
            if let newProfileURL = await userService.uploadProfilePhoto(userID: userID, image: image) {
                DispatchQueue.main.async {
                    self.user?.profilePhoto = newProfileURL
                }
            }
        }
    }
    
    // MARK: - フォロー関連の機能（UserService 経由）
    
    /// 現在ログイン中のユーザーがこのプロフィールを既にフォローしているか確認する
    func checkFollowingStatus() {
        Task {
            guard let currentUserID = userManager.currentUser?.uid,
                  let profileUserID = user?.uid,
                  currentUserID != profileUserID else { return }
            let status = await userService.checkFollowingStatus(currentUserID: currentUserID, profileUserID: profileUserID)
            DispatchQueue.main.async {
                self.isFollowing = status
            }
        }
    }
    
    /// フォローする処理（UserService 経由）
    func follow() {
        Task {
            guard let currentUserID = userManager.currentUser?.uid,
                  let profileUserID = user?.uid,
                  currentUserID != profileUserID else { return }
            let success = await userService.followUser(currentUserID: currentUserID, profileUserID: profileUserID)
            if success {
                DispatchQueue.main.async {
                    self.isFollowing = true
                    self.followersCount += 1
                }
            }
        }
    }
    
    /// フォロー解除する処理（UserService 経由）
    func unfollow() {
        Task {
            guard let currentUserID = userManager.currentUser?.uid,
                  let profileUserID = user?.uid,
                  currentUserID != profileUserID else { return }
            let success = await userService.unfollowUser(currentUserID: currentUserID, profileUserID: profileUserID)
            if success {
                DispatchQueue.main.async {
                    self.isFollowing = false
                    self.followersCount -= 1
                }
            }
        }
    }
}
