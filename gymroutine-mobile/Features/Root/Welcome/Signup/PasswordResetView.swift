import SwiftUI

struct PasswordResetView: View {

    @StateObject private var viewModel = PasswordResetViewModel(authService: AuthService())

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 56) {
                    InputForm

                    VStack(spacing: 16) {
                        sendResetLinkButton

                        resetStatusMessage
                    }
                }

                Spacer()
            }
            .padding(.bottom, 16)
            .padding([.top, .horizontal], 24)
            .background()
            .navigationTitle("パスワードのリセット")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var InputForm: some View {
        VStack(alignment: .center, spacing: 40) {
            VStack(alignment: .leading, spacing: 12) {
                Text("メールアドレス")
                    .fontWeight(.semibold)

                EmailAddressField(text: $viewModel.email)
            }
        }
    }

    private var sendResetLinkButton: some View {
        Button(action: {
            viewModel.sendPasswordReset()
        }) {
            Text("リセットリンクを送信")
        }
        .buttonStyle(PrimaryButtonStyle())
    }

    private var resetStatusMessage: some View {
        Group {
            if viewModel.isResetLinkSent {
                Text("リセットリンクを送信しました。メールを確認してください。")
                    .foregroundColor(.green)
            }
        }
        .font(.callout)
    }
}

#Preview {
    PasswordResetView()
}
