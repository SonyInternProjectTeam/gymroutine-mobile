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
    
    private let userManager = UserManager.shared
    private let userService = UserService()
    
    init(user:User? = nil){
        if let user = user {
            self.user = user
        }
    }
    
    func updateUser(newVisibility: Int?,newName: String?) {
        Task {
            UIApplication.showLoading()
            guard let userID = userManager.currentUser?.uid else { return }
            let updateSuccess = await userService.updateUserProfile(userID:userID, newVisibility: newVisibility, newName: newName)
            print("Profile更新%s\n",updateSuccess ? "成功" : "失敗")
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
                }
                
            }  else {
                print("Profile更新エラー")
            }
            UIApplication.hideLoading()
        }
    }
    
}
