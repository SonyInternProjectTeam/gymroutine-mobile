//
//  LoginView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/10/27.
//

import Foundation
import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel = LoginViewModel()
    @State private var showingSignup = false  // state

    var body: some View {
        NavigationStack {
            VStack {
                Text("Welcome")
                    .font(.largeTitle)
                    .padding()
                
                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: {
                    viewModel.login()
                }) {
                    Text("Login")
                        .font(.title)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()

                Button(action: {
                    showingSignup.toggle()  // move to signup page
                }) {
                    Text("Sign Up")
                        .font(.title)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                .sheet(isPresented: $showingSignup) {
                    SignupView()  // signup page modal
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                Spacer()
                
                // if login move to SuccessView
                NavigationLink(destination: SuccessView(), isActive: $viewModel.isLoggedIn) {
                    EmptyView()
                }
            }
            .padding()
        }
    }
}

#Preview {
    LoginView()
}
