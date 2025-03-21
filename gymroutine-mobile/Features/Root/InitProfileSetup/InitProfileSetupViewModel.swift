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
import SwiftUI

@MainActor
final class InitProfileSetupViewModel: ObservableObject {
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var name: String = ""
    @Published var age: Int = 0
    @Published var gender: Gender? = nil
    @Published var birthday: Date = Date()
    @Published var isSignedUp: Bool = false
    @Published var currentStep: SetupStep = .nickname

    private let router: Router
    private var cancellables = Set<AnyCancellable>()
    private let authService = AuthService()
    let setupSteps: [SetupStep] = SetupStep.allCases

    init(router: Router) {
        self.router = router

        // 初期値 2000年1月1日
        birthday = Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? Date()
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
            birthday: self.birthday,
            gender: self.gender?.rawValue ?? Gender.noAnswer.rawValue,
            createdAt: Date()
        )
        
        Task {
            UIApplication.showLoading()
            let saveResult = await authService.saveUserInfo(user: user)
            switch saveResult {
            case .success(_):
                router.switchRootView(to: .main(user: user))
            case .failure(let error):
                UIApplication.showBanner(type: .error, message: error.localizedDescription)
            }
            UIApplication.hideLoading()
        }
    }

    /// on tap gender button
    func selectGender(_ gender: Gender) {
        self.gender = gender
    }

    /// for gender button UI
    func isSelectedGender(_ gender: Gender) -> Bool {
        return self.gender == gender
    }

    func isDisabledActionButton() -> Bool {
        switch currentStep {
        case .nickname:
            return name.isEmpty
        case .gender:
            return gender == nil
        case .birthday:
            return false
        }
    }

    func moveToStep(_ step: SetupStep) {
        self.currentStep = step
    }
}

// MARK: - Enums
extension InitProfileSetupViewModel {
    enum SetupStep: CaseIterable {
        case nickname
        case gender
        case birthday

        var nextStep: SetupStep? {
            guard let currentIndex = Self.allCases.firstIndex(of: self),
                  currentIndex < Self.allCases.count - 1 else {
                return nil
            }
            return Self.allCases[currentIndex + 1]
        }

        var previousStep: SetupStep? {
            guard let currentIndex = Self.allCases.firstIndex(of: self),
                  currentIndex > 0 else {
                return nil
            }
            return Self.allCases[currentIndex - 1]
        }
    }

    enum Gender: String, CaseIterable {
        case man = "男性"
        case woman = "女性"
        case noAnswer = "無回答"
    }
}
