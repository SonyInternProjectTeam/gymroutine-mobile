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
    @Published var isFollowing: Bool = false  // 현재 로그인 중인 사용자가 이 프로필을 팔로우 중인지
    @Published var selectedTab: ProfileTab = .analysis
    @Published var workouts: [Workout] = []   // 추가: 워크아웃 목록
    
    private let userManager = UserManager.shared
    private let userService = UserService()
    private let followService = FollowService()
    private let workoutRepository = WorkoutRepository()  // Repository 인스턴스
    
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
            }
            // 워크아웃 데이터 불러오기
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
    
    /// Repository를 통해 워크아웃 데이터를 불러옵니다.
    func fetchWorkouts() async {
        guard let userID = user?.uid else {
            print("ERROR: fetchWorkouts - 사용자 ID가 없습니다")
            return 
        }
        
        print("DEBUG: 사용자 ID: \(userID)의 워크아웃 데이터를 불러옵니다")
        do {
            let fetchedWorkouts = try await workoutRepository.fetchWorkouts(for: userID)
            print("DEBUG: 워크아웃 \(fetchedWorkouts.count)개 로드 완료")
            DispatchQueue.main.async {
                self.workouts = fetchedWorkouts
            }
        } catch {
            print("ERROR: 워크아웃 로드 실패: \(error)")
        }
    }
}
