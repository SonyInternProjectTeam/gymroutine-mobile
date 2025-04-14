//
//  ProfileViewModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/01/02.
//

import Foundation
import PhotosUI
import SwiftUI
import FirebaseFunctions

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var followersCount: Int = 0
    @Published var followingCount: Int = 0
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var isFollowing: Bool = false
    @Published var selectedTab: ProfileTab = .analysis
    @Published var workoutStats: WorkoutStats? = nil

    private let userManager = UserManager.shared
    private let userService = UserService()
    private let followService = FollowService()
    private let functions: FirebaseFunctions.Functions = Functions.functions()

    enum ProfileTab: String, CaseIterable {
        case analysis = "分析"
        case posts = "投稿"

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
        self.user = user
        // 初期化後に非同期処理を実行するために、DispatchQueue.mainを使用
        DispatchQueue.main.async {
            self.setupInitialData()
        }
    }
    
    private func setupInitialData() {
        Task {
            if let user = self.user {
                await loadFollowerAndFollowingCounts(userId: user.uid)
                if !isCurrentUser {
                    await updateFollowingStatus()
                }
            } else {
                await loadUserData()
            }
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
    func loadUserData() async {
        if let currentUser = userManager.currentUser {
            self.user = currentUser
            await loadFollowerAndFollowingCounts(userId: currentUser.uid)
        } else {
            print("UserManagerからユーザー情報を読み込めませんでした")
        }
    }
    
    /// フォロワーとフォロー中の数を読み込む
    /// - Parameter userId: ユーザーのUID
    private func loadFollowerAndFollowingCounts(userId: String) async {
        UIApplication.showLoading()
        let followers = await userManager.fetchFollowersCount(userId: userId)
        let following = await userManager.fetchFollowingCount(userId: userId)
        DispatchQueue.main.async {
            self.followersCount = followers
            self.followingCount = following
        }
        UIApplication.hideLoading()
    }
    
    /// 現在ログイン中のユーザーがこのプロフィールを既にフォローしているか確認する
    func updateFollowingStatus() async {
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

    /// プロフィール写真をアップロードする処理
    /// - Parameter image: アップロードするUIImage
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
    
    /// フォローする処理
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
    
    /// フォロー解除する処理
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
    
    /// PhotosPickerで選択された写真の変更を処理する
    /// - Parameter newItem: 変更後のPhotosPickerItem
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
    
    /// ワークアウト統計データを取得
func fetchWorkoutStats() {
    Task {
        UIApplication.showLoading()
        do {
            print("Fetching workout stats...")
            let result = try await functions.httpsCallable("getWorkoutStats").call()
            print("Received result: \(result)")
            
            if let data = result.data as? [String: Any] {
                print("Parsing data: \(data)")
                DispatchQueue.main.async {
                    self.workoutStats = WorkoutStats(
                        totalWorkouts: data["totalWorkouts"] as? Int ?? 0,
                        partFrequency: data["partFrequency"] as? [String: Int] ?? [:],
                        weightProgress: data["weightProgress"] as? [String: [Double]] ?? [:]
                    )
                    print("Updated workoutStats: \(String(describing: self.workoutStats))")
                }
            } else {
                print("Failed to parse result data")
                // テスト用のモックデータを設定
                DispatchQueue.main.async {
                    self.workoutStats = WorkoutStats(
                        totalWorkouts: 10,
                        partFrequency: [
                            "arm": 5,
                            "chest": 3,
                            "back": 2
                        ],
                        weightProgress: [
                            "ベンチプレス": [60.0, 65.0, 70.0],
                            "スクワット": [80.0, 85.0, 90.0]
                        ]
                    )
                }
            }
        } catch {
            print("Error fetching workout stats: \(error.localizedDescription)")
            // エラー時もモックデータを設定
            DispatchQueue.main.async {
                self.workoutStats = WorkoutStats(
                    totalWorkouts: 10,
                    partFrequency: [
                        "arm": 5,
                        "chest": 3,
                        "back": 2
                    ],
                    weightProgress: [
                        "ベンチプレス": [60.0, 65.0, 70.0],
                        "スクワット": [80.0, 85.0, 90.0]
                    ]
                )
            }
        }
        UIApplication.hideLoading()
        }
    }
}