//
//  SignupView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/10/28.
//

import SwiftUI

struct SignupView: View {
    @ObservedObject var viewModel = SignupViewModel()
    @State private var navigateToSecondView = false

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

            HStack(spacing: 0) {
                Spacer()

                Button(action: {
                    viewModel.signupWithEmailAndPassword { success in
                        if success {
                            navigateToSecondView = true
                        }
                    }
                }) {
                    Text("次へ")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.bottom, 16)
        .padding([.top, .horizontal], 24)
        .navigationTitle("新規登録")
        .navigationBarTitleDisplayMode(.inline)
        .background(
            NavigationLink(
                destination: SignupViewSecond(viewModel: viewModel),
                isActive: $navigateToSecondView
            ) {
                EmptyView()
            }
        )
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

                PasswordField(text: $viewModel.password, placeholder: "6文字以上")

                PasswordField(text: $viewModel.confirmPassword, placeholder: "確認用")
            }
        }
    }
}

#Preview {
    SignupView()
}
