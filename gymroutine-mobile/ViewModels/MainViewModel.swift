//
//  MainViewModel.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2024/12/26
//  
//

import Foundation
import FirebaseAuth

// Todo : UserManagerからユーザー情報撮って状態管理

@MainActor
final class MainViewModel: ObservableObject {
    private let router: Router
    private let authService = AuthService()
    @Published private(set) var userManager: UserManager = .shared

    init(router: Router) {
        self.router = router
    }

    func logout() {
        authService.logout()
        userManager.currentUser = nil
        userManager.isLoggedIn = false
        router.switchRootView(to: .welcome)
    }
}

