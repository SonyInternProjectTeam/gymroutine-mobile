import Foundation
import FirebaseAuth
import Combine

class PasswordResetViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var birthday: Date = Date()
    @Published var errorMessage: String? = nil
    @Published var isResetLinkSent: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    func sendPasswordReset() {
        // 入力チェック
        guard !email.isEmpty else {
            errorMessage = "メールアドレスを入力してください。"
            return
        }

        // パスワードリセット処理
        authService.sendPasswordReset(email: email, birthday: birthday) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.isResetLinkSent = true
                    self?.errorMessage = nil
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
