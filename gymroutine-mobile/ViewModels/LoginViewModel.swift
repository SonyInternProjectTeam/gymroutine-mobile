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
    
    func login(completion: @escaping (User?) -> Void) {
        authService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                }
            }, receiveValue: { user in
                if let user = user {
                    self.isLoggedIn = true  // 상태 업데이트
                    self.errorMessage = nil
                    completion(user)  // 성공 시 유저 전달
                } else {
                    self.isLoggedIn = false
                    self.errorMessage = "login failed"
                    completion(nil)  // 실패 시 콜백에 nil 전달
                }
            })
            .store(in: &cancellables)
    }

}
