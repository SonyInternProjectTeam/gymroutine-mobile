//
//  LoginViewModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/10/28.
//
import Foundation
import Combine

class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String? = nil
    @Published var isLoggedIn: Bool = false  // login state
    
    private var cancellables = Set<AnyCancellable>()
    private let authService: AuthService
    
    init(authService: AuthService = AuthService()) {
        self.authService = authService
    }
    
    func login() {
        authService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                }
            }, receiveValue: { user in
                if let _ = user {
                    self.isLoggedIn = true  // chagne state after login
                    self.errorMessage = nil
                } else {
                    self.isLoggedIn = false
                    self.errorMessage = "login failed"
                }
            })
            .store(in: &cancellables)
    }
}
