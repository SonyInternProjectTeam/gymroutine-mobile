//
//  LoginView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/10/27.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel

    @State private var isShowingPasswordReset = false

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            InputForm

            Button(action: {
                isShowingPasswordReset = true
            }) {
                Text("パスワードを忘れた方はこちら")
                    .font(.callout)
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 16)
            .hAlign(.leading)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .hAlign(.leading)
            }

            Spacer()

            // TODO: disable対応
            Button(action: {
                viewModel.login()
            }) {
                Text("ログイン")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.bottom, 16)
        .padding([.top, .horizontal], 24)
        .navigationTitle("ログイン")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingPasswordReset) {
            PasswordResetView()
        }
    }

    private var InputForm: some View {
        VStack(alignment: .center, spacing: 40) {
            VStack(alignment: .leading, spacing: 12) {
                Text("メールアドレス")
                    .fontWeight(.semibold)
              
                EmailAddressField(text: $viewModel.email)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("パスワード")
                    .fontWeight(.semibold)

                PasswordField(text: $viewModel.password)
            }
        }
    }
}

#Preview {
    NavigationStack {
        LoginView(viewModel: LoginViewModel(router: Router()))
    }
}
