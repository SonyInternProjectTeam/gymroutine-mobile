//
//  SplashViewModel.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2024/12/26
//  
//

import Foundation
import FirebaseAuth

@MainActor
final class SplashViewModel: ObservableObject {
    
    private let authService: AuthService = AuthService()
    private let router: Router
    private let userManager = UserManager.shared
    
    init(router: Router) {
        self.router = router
        switchView()
    }
    
    private func switchView() {
        guard let currentUser = authService.getCurrentUser() else {
            router.switchRootView(to: .welcome)
            return
        }
        
        Task {
            await userManager.initializeUser()
            //ローディングView表示
            let fetchResult = await authService.fetchUser(uid: currentUser.uid)
            switch fetchResult {
            case .success(let user):
                router.switchRootView(to: .main(user: user))
            case .failure(let error):
                print("[ERROR] \(error.localizedDescription)")
                router.switchRootView(to: .initProfileSetup)
            }
            //ローディングView非表示
        }
    }
}
