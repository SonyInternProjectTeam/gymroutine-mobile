//
//  WelcomeView.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2024/12/26
//  
//

import SwiftUI

struct WelcomeView: View {
    
    let router: Router
    private let analyticsService = AnalyticsService.shared
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 40) {
                VStack(spacing: 24) {
                    Image(.welcomeLogo)
                        .resizable()
                        .scaledToFit()
                        .hAlign(.center)

                    Text("GymLinkerへようこそ！")
                        .font(.title2.bold())
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 16) {
                    NavigationLink(
                        destination:
                            SignupView(
                                viewModel: SignupViewModel(router: router)
                            )
                    ) {
                        Text("新規登録")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    NavigationLink(
                        destination:
                            LoginView(
                                viewModel: LoginViewModel(router: router)
                            )
                    ) {
                        Text("ログイン")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .vAlign(.center)
            .padding(.horizontal, 48)
            .onAppear {
                // Log screen view
                analyticsService.logScreenView(screenName: "Welcome")
            }
        }
    }
}

#Preview {
    WelcomeView(router: Router())
}
