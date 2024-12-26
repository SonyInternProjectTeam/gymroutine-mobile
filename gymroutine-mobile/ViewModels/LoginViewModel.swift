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
                    self.errorMessage = error.localizedDescription
                }
            }, receiveValue: { user in
                if let user = user {
                    self.errorMessage = nil
                    DispatchQueue.main.async {
                        self.router.switchRootView(to: .main(user: user))
                    }
                } else {
                    self.errorMessage = "login failed"
                }
            })
            .store(in: &cancellables)
    }
}
