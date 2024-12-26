//
//  InitProfileSetupViewModel.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2024/12/26
//  
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
final class InitProfileSetupViewModel: ObservableObject {
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var name: String = ""
    @Published var age: Int = 0
    @Published var gender: String = ""
    @Published var birthday: Date = Date()
    @Published var errorMessage: String? = nil
    @Published var isSignedUp: Bool = false
    
    private let router: Router
    private var cancellables = Set<AnyCancellable>()
    private let authService = AuthService()
    
    init(router: Router) {
        self.router = router
    }

    /// Firestore - save user info
    func saveAdditionalInfo() {
        guard let currentUser = Auth.auth().currentUser else {
            fatalError("[ERROR] Userが存在しません")
        }
        let uid = currentUser.uid
        guard let email = currentUser.email else {
            fatalError("[ERROR] emailが存在しません")
        }
        
        let user = User(
            uid: uid,
            email: email,
            name: self.name,
            profilePhoto: "",
            visibility: 2,
            isActive: false,
            createdAt: Date()
        )
        
        Task {
            //ローディング画面表示
            let saveResult = await authService.saveUserInfo(user: user)
            switch saveResult {
            case .success(_):
                router.switchRootView(to: .main(user: user))
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
            //ローディング画面非表示
        }
    }
}
