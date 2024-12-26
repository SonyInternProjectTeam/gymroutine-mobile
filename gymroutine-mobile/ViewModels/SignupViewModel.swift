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
    @Published var name: String = ""
    @Published var age: Int = 0
    @Published var gender: String = ""
    @Published var birthday: Date = Date()
    @Published var errorMessage: String? = nil
    @Published var userUID: String? = nil
    @Published var isSignedUp: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let authService: AuthService
    
    init(authService: AuthService = AuthService()) {
        self.authService = authService
    }

    /// Firebase Authentication - create account
    func signupWithEmailAndPassword(completion: @escaping (Bool) -> Void) {
        guard password == confirmPassword else {
            self.errorMessage = "Passwords do not match"
            completion(false)
            return
        }

        authService.createUser(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completionResult in
                switch completionResult {
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    print("Error creating user: \(error.localizedDescription)")
                    completion(false)
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] userUID in
                self?.userUID = userUID
                print("User UID: \(userUID)") // 로그 추가
                self?.errorMessage = nil
                completion(true)
            })
            .store(in: &cancellables)
    }

    /// Firestore - save user info
    func saveAdditionalInfo(user: User, completion: @escaping (Bool) -> Void) {
        guard !user.uid.isEmpty else {
            self.errorMessage = "User UID not found"
            completion(false)
            return
        }

        authService.saveUserInfo(user: user)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completionResult in
                switch completionResult {
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                case .finished:
                    break
                }
            }, receiveValue: {
                completion(true)
            })
            .store(in: &cancellables)
    }
}

