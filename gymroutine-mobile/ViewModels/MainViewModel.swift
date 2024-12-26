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
    let user: User
    private let authService = AuthService()
    
    init(router: Router, user: User) {
        self.router = router
        self.user = user
    }
    
    //あとで消してね
    func logout() {
        authService.logout()
        router.switchRootView(to: .welcome)
    }
}
