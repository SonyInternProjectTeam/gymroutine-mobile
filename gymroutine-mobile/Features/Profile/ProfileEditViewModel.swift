//
//  ProfileEditViewModel.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2025/04/15.
//

import Foundation
import SwiftUI

@MainActor
final class ProfileEditViewModel: ObservableObject {
    @Published var user: User?
    @Published var isUpdating: Bool = false
    @Published var updateSuccess: Bool = false
    @Published var showMessage: Bool = false
    @Published var errorMessage: String = ""
    
    private let userManager = UserManager.shared
    private let userService = UserService()
    private let authService = AuthService()
    let router: Router

    init(user:User, router: Router) {
        self.user = user
        self.router = router
    }
    
    func updateUser(newVisibility: Int?,newName: String?) {
        Task {
            isUpdating = true
            UIApplication.showLoading()
            guard let userID = userManager.currentUser?.uid else { return }
            let updateSuccess = await userService.updateUserProfile(userID:userID, newVisibility: newVisibility, newName: newName)
            print("Profile更新%s", updateSuccess ? "成功" : "失敗")
            if updateSuccess {
                DispatchQueue.main.async {
                    if let visibility = newVisibility {
                        self.user?.visibility = visibility
                        self.userManager.currentUser?.visibility = visibility
                    }
                    if let name = newName {
                        self.user?.name = name
                        self.userManager.currentUser?.name = name
                    }
                    self.updateSuccess = true
                    self.showMessage = true
                }
                
            }  else {
                DispatchQueue.main.async {
                    self.errorMessage = "プロフィールの更新に失敗しました。"
                    self.updateSuccess = false
                    self.showMessage = true
                }
            }
            isUpdating = false
            UIApplication.hideLoading()
        }
    }
    
    func refreshUserData() {
        Task {
            guard let userID = userManager.currentUser?.uid else { return }
            
            let result = await authService.fetchUser(uid: userID)
            
            switch result {
            case .success(let updatedUser):
                DispatchQueue.main.async {
                    self.user = updatedUser
                    self.userManager.currentUser = updatedUser
                }
            case .failure(let error):
                print("Failed to refresh user data: \(error.localizedDescription)")
            }
        }
    }
    
    /// Log out the current user
    func logout() {
        authService.logout()
        // 로그아웃 후 welcome 화면으로 이동
        router.switchRootView(to: .welcome)
    }
    
    /// Delete the current user's account
    func deleteAccount() {
        Task {
            UIApplication.showLoading()
            let success = await authService.deleteAccount()
            UIApplication.hideLoading()
            
            if !success {
                // Handle deletion failure - could show an alert
                print("アカウント削除に失敗しました")
            } else {
                // 계정 삭제 성공 시 welcome 화면으로 이동
                router.switchRootView(to: .welcome)
            }
            // On success, AuthService already updates UserManager state
            // which should trigger navigation to login screen
        }
    }
}
