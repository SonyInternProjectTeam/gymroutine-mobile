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
    @Published var selectedPhotoItem: PhotosPickerItem? {
        didSet { // ✅ selectedPhotoItem이 변경될 때 자동 실행
            Task {
                if let newItem = selectedPhotoItem, let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    uploadProfilePhoto(image)
                }
            }
        }
    }
    
    private let userManager = UserManager.shared
    private let userService = UserService()

    init() {
        loadUserData()
    }
    
    func loadUserData() {
        if let currentUser = userManager.currentUser {
            self.user = currentUser
            loadFollowerAndFollowingCounts(userId: currentUser.uid)
        } else {
            print("UserManagerからユーザー情報を読み込めませんでした")
        }
    }
    
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
}
