//
//  SignupViewModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/10/28.
//

import Foundation
import Combine

class SignupViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var errorMessage: String? = nil
    @Published var isSignedUp: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let authService: AuthService
    
    init(authService: AuthService = AuthService()) {
        self.authService = authService
    }
    
    func signup() {
        guard password == confirmPassword else {
            self.errorMessage = "Passwords do not match"
            return
        }
        
        authService.signup(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                }
            }, receiveValue: { user in
                if let _ = user {
                    self.isSignedUp = true
                    self.errorMessage = nil
                } else {
                    self.isSignedUp = false
                    self.errorMessage = "Signup failed"
                }
            })
            .store(in: &cancellables)
    }
}

