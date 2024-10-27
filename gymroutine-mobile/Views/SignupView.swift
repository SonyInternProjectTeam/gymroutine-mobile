//
//  SignupView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/10/28.
//

import SwiftUI

struct SignupView: View {
    @ObservedObject var viewModel = SignupViewModel()

    var body: some View {
        VStack {
            Text("Sign Up")
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
            
            SecureField("Confirm Password", text: $viewModel.confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                viewModel.signup()
            }) {
                Text("Sign Up")
                    .font(.title)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            if viewModel.isSignedUp {
                Text("Signup Success! Please log in.")
                    .foregroundColor(.green)
                    .padding()
            }

            Spacer()
        }
        .padding()
    }
}

