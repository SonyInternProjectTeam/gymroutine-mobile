//
//  LoginViewModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/10/28.
//
import Foundation
import Combine
import SwiftUI

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let authService = AuthService()
    private let router: Router
    private let userManager = UserManager.shared
    
    init(router: Router) {
        self.router = router
        userManager.$isLoggedIn
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoggedIn in
                guard let self = self else { return }
                
                if isLoggedIn, let authenticatedUser = self.userManager.currentUser {
                    // Only navigate if the current route is .welcome
                    if case .welcome = self.router.route { // Corrected check
                        print("[LoginViewModel] isLoggedIn is true, currentUser exists, current route is .welcome. Attempting to switch to main view.")
                        self.router.switchRootView(to: .main(user: authenticatedUser))
                    }
                } else if !isLoggedIn {
                    // Optional: If user becomes logged out, ensure they are on the welcome screen.
                    // This might be useful if a session expires while the app is open on a main screen.
                    // if case .main(_) = self.router.route { // Check if current route is .main
                    //    print("[LoginViewModel] User logged out, current route is .main. Switching to .welcome.")
                    //    self.router.switchRootView(to: .welcome)
                    // }
                }
            }
            .store(in: &cancellables)
    }
    
    func login() {
        isLoading = true
        authService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    UIApplication.showBanner(type: .error, message: error.localizedDescription)
                }
            }, receiveValue: { _ in
                // AuthService.login은 이제 User? 대신 Void? 또는 다른 의미 없는 값을 반환하거나,
                // 아예 User 객체를 반환하지 않도록 수정될 수 있습니다.
                // 현재 로직에서는 이 receiveValue를 사용하지 않습니다.
            })
            .store(in: &cancellables)
    }
}
