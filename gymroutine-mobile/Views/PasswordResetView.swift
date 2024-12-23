import SwiftUI

struct PasswordResetView: View {
    @StateObject private var viewModel = PasswordResetViewModel(authService: AuthService())

    var body: some View {
        VStack(spacing: 20) {
            Text("パスワードリセット")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField("メールアドレスを入力してください", text: $viewModel.email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()

            DatePicker("生年月日を選択してください", selection: $viewModel.birthday, displayedComponents: .date)

            // エラーメッセージ表示
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button(action: {
                viewModel.sendPasswordReset()
            }) {
                Text("リセットリンクを送信")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            if viewModel.isResetLinkSent {
                Text("リセットリンクを送信しました。メールを確認してください。")
                    .foregroundColor(.green)
                    .font(.caption)
            }

            Spacer()
        }
        .padding()
    }
}
