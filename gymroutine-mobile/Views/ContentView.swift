//
//  ContentView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/10/27.
//


import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 40) {
                VStack(spacing: 24) {
                    Image(.welcomeLogo)
                        .resizable()
                        .scaledToFit()
                        .hAlign(.center)

                    Text("ジムルーティーンへようこそ！")
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 16) {
                    NavigationLink(destination: SignupView()) {
                        Text("新規登録")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    NavigationLink(destination: LoginView()) {
                        Text("ログイン")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .vAlign(.center)
            .padding(.horizontal, 48)
        }
    }
}

#Preview {
    ContentView()
}
