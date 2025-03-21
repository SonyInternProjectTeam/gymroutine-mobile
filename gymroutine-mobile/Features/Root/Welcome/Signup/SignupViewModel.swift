//
//  SignupViewModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/10/28.
//

import Foundation
import Combine
import SwiftUI

class SignupViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var name: String = ""
    @Published var age: Int = 0
    @Published var gender: String = ""
    @Published var birthday: Date = Date()
    @Published var userUID: String? = nil
    @Published var isSignedUp: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let authService = AuthService()
    let router: Router
    
    init(router: Router) {
        self.router = router
    }

    /// Firebase Authentication - create account
    func signupWithEmailAndPassword(completion: @escaping (Bool) -> Void) {
        guard password == confirmPassword else {
            UIApplication.showBanner(type: .error, message: "パスワードが一致していません。")
            completion(false)
            return
        }

        authService.createUser(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completionResult in
                switch completionResult {
                case .failure(let error):
                    UIApplication.showBanner(type: .error, message: error.localizedDescription)
                    print("Error creating user: \(error.localizedDescription)")
                    completion(false)
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] userUID in
                self?.userUID = userUID
                print("User UID: \(userUID)") // 로그 추가
                completion(true)
            })
            .store(in: &cancellables)
    }
}

