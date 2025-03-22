//
//  LoginViewModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/10/28.
//
import Foundation
import Combine
import SwiftUI

class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let authService = AuthService()
    private let router: Router
    
    init(router: Router) {
        self.router = router
    }
    
    func login() {
        authService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    UIApplication.showBanner(type: .error, message: error.localizedDescription)
                }
            }, receiveValue: { user in
                if let user = user {
                    DispatchQueue.main.async {
                        self.router.switchRootView(to: .main(user: user))
                    }
                } else {
                    UIApplication.showBanner(type: .error, message: "login failed")
                }
            })
            .store(in: &cancellables)
    }
}
