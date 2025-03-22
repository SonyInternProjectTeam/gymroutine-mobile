



import Foundation
import FirebaseAuth
import Combine
import SwiftUI

class PasswordResetViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var birthday: Date = Date()
    @Published var isResetLinkSent: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService

        // 初期値 2000年1月1日
        birthday = Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? Date()
    }

    func sendPasswordReset() {
        // 入力チェック
        guard !email.isEmpty else {
            UIApplication.showBanner(type: .error, message: "メールアドレスを入力してください。")
            return
        }

        // パスワードリセット処理
        authService.sendPasswordReset(email: email, birthday: birthday) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.isResetLinkSent = true
                case .failure(let error):
                    UIApplication.showBanner(type: .error, message: error.localizedDescription)
                }
            }
        }
    }
}
