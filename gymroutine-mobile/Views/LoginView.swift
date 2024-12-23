//
//  LoginView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/10/27.
//

import SwiftUI

struct LoginView: View {

    @ObservedObject var viewModel = LoginViewModel()
    @State private var isShowingPasswordReset = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            InputForm

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top, 8)
                    .padding(.leading, 4)
            }

            Spacer()

            // TODO: disable対応
            Button(action: {
                viewModel.login()
            }) {
                Image(systemName: "chevron.forward")
            }
            .buttonStyle(CircleButtonStyle())
            .hAlign(.trailing)

            Button(action: {
                isShowingPasswordReset = true
            }) {
                Text("パスワードを忘れた方はこちら")
                    .font(.footnote)
                    .foregroundColor(.blue)
                    .padding(.top, 8)
            }
            .sheet(isPresented: $isShowingPasswordReset) {
                PasswordResetView()
            }
        }
        .padding(.bottom, 16)
        .padding([.top, .horizontal], 24)
        .navigationTitle("ログイン")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $viewModel.isLoggedIn) {
            SuccessView()
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
        LoginView()
    }
}
