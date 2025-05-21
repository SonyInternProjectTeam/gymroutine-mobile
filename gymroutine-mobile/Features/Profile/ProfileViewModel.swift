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
    @Published var isFollowing: Bool = false  // 現在ログイン中のユーザーがこのプロフィールをフォロー中かどうか
    @Published var selectedTab: ProfileTab = .analysis
    @Published var workouts: [Workout] = []   // 追加: ワークアウトリスト
    @Published var isBlocked: Bool = false    // 追加: ユーザーがブロックされているかどうか
    
    private let userManager = UserManager.shared
    private let userService = UserService()
    private let followService = FollowService()
    private let workoutRepository = WorkoutRepository()  // Repository インスタンス
    private let analyticsService = AnalyticsService.shared
    
    enum ProfileTab: String, CaseIterable {
        case analysis = "分析"
        case posts = "ワークアウト"
        
        func toString() -> String {
            rawValue
        }
        
        func imageName() -> String {
            switch self {
            case .analysis:
                return "chart.bar.xaxis"
            case .posts:
                return "doc.plaintext"
            }
        }
    }
    
    init(user: User? = nil) {
        if let user = user {
            self.user = user
            loadFollowerAndFollowingCounts(userId: user.uid)
            if !isCurrentUser {
                updateFollowingStatus()
                checkBlockedStatus()  // 追加: ブロック状態を確認
            }
            // ワークアウトデータの読み込み
            Task {
                await fetchWorkouts()
            }
        } else {
            loadUserData()
        }
    }
    
    var isCurrentUser: Bool {
        if let user = user, let currentUser = userManager.currentUser {
            return user.uid == currentUser.uid
        }
        return false
    }
    
    func loadUserData() {
        if let currentUser = userManager.currentUser {
            self.user = currentUser
            loadFollowerAndFollowingCounts(userId: currentUser.uid)
            Task {
                await fetchWorkouts()
            }
        } else {
            print("UserManagerからユーザー情報を読み込めませんでした")
        }
    }
    
    private func loadFollowerAndFollowingCounts(userId: String) {
        Task {
            UIApplication.showLoading()
            let followers = await userManager.fetchFollowersCount(userId: userId)
            let following = await userManager.fetchFollowingCount(userId: userId)
            DispatchQueue.main.async {
                self.followersCount = followers
                self.followingCount = following
            }
            UIApplication.hideLoading()
        }
    }
    
    func uploadProfilePhoto(_ image: UIImage) {
        Task {
            UIApplication.showLoading()
            guard let userID = userManager.currentUser?.uid else { return }
            if let newProfileURL = await userService.uploadProfilePhoto(userID: userID, image: image) {
                DispatchQueue.main.async {
                    self.user?.profilePhoto = newProfileURL
                }
            }
            UIApplication.hideLoading()
        }
    }
    
    func updateFollowingStatus() {
        Task {
            UIApplication.showLoading()
            guard let currentUserID = userManager.currentUser?.uid,
                  let profileUserID = user?.uid,
                  currentUserID != profileUserID else { return }
            let status = await followService.checkFollowingStatus(currentUserID: currentUserID, profileUserID: profileUserID)
            DispatchQueue.main.async {
                self.isFollowing = status
            }
            UIApplication.hideLoading()
        }
    }
    
    func follow() {
        Task {
            UIApplication.showLoading()
            guard let currentUserID = userManager.currentUser?.uid,
                  let profileUserID = user?.uid,
                  currentUserID != profileUserID else { return }
            let success = await followService.followUser(currentUserID: currentUserID, profileUserID: profileUserID)
            if success {
                DispatchQueue.main.async {
                    self.isFollowing = true
                    self.followersCount += 1
                }
            }
            UIApplication.hideLoading()
        }
    }
    
    func unfollow() {
        Task {
            UIApplication.showLoading()
            guard let currentUserID = userManager.currentUser?.uid,
                  let profileUserID = user?.uid,
                  currentUserID != profileUserID else { return }
            let success = await followService.unfollowUser(currentUserID: currentUserID, profileUserID: profileUserID)
            if success {
                DispatchQueue.main.async {
                    self.isFollowing = false
                    self.followersCount -= 1
                }
            }
            UIApplication.hideLoading()
        }
    }
    
    func handleSelectedPhotoItemChange(_ newItem: PhotosPickerItem?) {
        Task {
            UIApplication.showLoading()
            if let newItem = newItem,
               let data = try? await newItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                self.uploadProfilePhoto(image)
            }
            UIApplication.hideLoading()
        }
    }
    
    /// Repositoryを通じてワークアウトデータを読み込みます。
    func fetchWorkouts() async {
        guard let userID = user?.uid else {
            print("ERROR: fetchWorkouts - ユーザーIDがありません")
            return 
        }
        
        print("DEBUG: ユーザーID: \(userID)のワークアウトデータを読み込みます")
        do {
            let fetchedWorkouts = try await workoutRepository.fetchWorkouts(for: userID)
            print("DEBUG: ワークアウト \(fetchedWorkouts.count)個をロード完了")
            DispatchQueue.main.async {
                self.workouts = fetchedWorkouts
            }
        } catch {
            print("ERROR: ワークアウトのロードに失敗: \(error)")
        }
    }
    
    /// ユーザーがブロックされているか確認する
    private func checkBlockedStatus() {
        guard let currentUserID = userManager.currentUser?.uid,
              let targetUserID = user?.uid else { return }
        
        Task {
            let blocked = await userService.isUserBlocked(currentUserID: currentUserID, targetUserID: targetUserID)
            DispatchQueue.main.async {
                self.isBlocked = blocked
            }
        }
    }
    
    // MARK: - User Blocking and Reporting
    
    /// ユーザーをブロックする
    func blockUser() {
        guard let currentUserID = userManager.currentUser?.uid,
              let blockedUserID = user?.uid,
              currentUserID != blockedUserID else { return }
        
        Task {
            UIApplication.showLoading()
            do {
                // ブロック処理を実行
                try await userService.blockUser(currentUserID: currentUserID, blockedUserID: blockedUserID)
                
                // 成功メッセージを表示
                UIApplication.showBanner(type: .success, message: "ユーザーをブロックしました")
                
                // アナリティクスにイベントを記録
                analyticsService.logUserAction(
                    action: "block_user",
                    itemId: blockedUserID,
                    contentType: "profile"
                )
                
                // ブロック状態を更新
                DispatchQueue.main.async {
                    self.isBlocked = true
                }
                
                // 必要に応じて画面を閉じるなどの処理
                // 例: NotificationCenter.default.post(name: .userBlocked, object: nil)
            } catch {
                print("ERROR: ユーザーのブロックに失敗: \(error)")
                UIApplication.showBanner(type: .error, message: "ユーザーのブロックに失敗しました")
            }
            UIApplication.hideLoading()
        }
    }
    
    /// ユーザーのブロックを解除する
    func unblockUser() {
        guard let currentUserID = userManager.currentUser?.uid,
              let blockedUserID = user?.uid,
              currentUserID != blockedUserID else { return }
        
        Task {
            UIApplication.showLoading()
            do {
                // ブロック解除処理を実行
                try await userService.unblockUser(currentUserID: currentUserID, blockedUserID: blockedUserID)
                
                // 成功メッセージを表示
                UIApplication.showBanner(type: .success, message: "ユーザーのブロックを解除しました")
                
                // アナリティクスにイベントを記録
                analyticsService.logUserAction(
                    action: "unblock_user",
                    itemId: blockedUserID,
                    contentType: "profile"
                )
                
                // ブロック状態を更新
                DispatchQueue.main.async {
                    self.isBlocked = false
                }
                
                // フォロー状態を再確認
                updateFollowingStatus()
            } catch {
                print("ERROR: ユーザーのブロック解除に失敗: \(error)")
                UIApplication.showBanner(type: .error, message: "ユーザーのブロック解除に失敗しました")
            }
            UIApplication.hideLoading()
        }
    }
    
    /// ユーザーを報告する
    func reportUser() {
        guard let currentUserID = userManager.currentUser?.uid,
              let reportedUserID = user?.uid,
              currentUserID != reportedUserID else { return }
        
        Task {
            UIApplication.showLoading()
            do {
                // 報告処理を実行
                try await userService.reportUser(currentUserID: currentUserID, reportedUserID: reportedUserID)
                
                // 成功メッセージを表示
                UIApplication.showBanner(type: .success, message: "ユーザーを報告しました")
                
                // アナリティクスにイベントを記録
                analyticsService.logUserAction(
                    action: "report_user",
                    itemId: reportedUserID,
                    contentType: "profile"
                )
            } catch {
                print("ERROR: ユーザーの報告に失敗: \(error)")
                UIApplication.showBanner(type: .error, message: "ユーザーの報告に失敗しました")
            }
            UIApplication.hideLoading()
        }
    }
}
