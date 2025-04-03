//
//  SnsViewModel.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2025/04/01.
//

import Foundation
import SwiftUI

@MainActor
final class SnsViewModel: ObservableObject {
    @Published var userDetails: [User] = []       // User 型の配列に変更
    @Published var searchName: String = ""
    @Published var errorMessage: String? = nil
    
    private let userService = UserService()
    
    /// ユーザー名でユーザー検索を行い、結果を userDetails に設定する
    func fetchUsers() {
        Task {
            UIApplication.showLoading()
            let result = await userService.searchUsersByName(name: searchName)
            switch result {
            case .success(let users):
                // 直接 User 型の配列を設定
                userDetails = users
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
            UIApplication.hideLoading()
        }
    }
}
