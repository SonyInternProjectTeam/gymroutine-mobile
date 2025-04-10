//
//  RootView.swift
//  gymroutine-mobile
//
//  Created by SATTSAT on 2024/12/26
//
//

import SwiftUI

struct RootView: View {
    @StateObject private var userManager = UserManager.shared
    @StateObject private var router = Router()
    
    var body: some View {
        switch router.route {
        case .splash:
            SplashView(viewModel: SplashViewModel(router: router))
            
        case .welcome:
            WelcomeView(router: router)
            
        case .initProfileSetup:
            InitProfileSetupView(
                viewModel: InitProfileSetupViewModel(router: router)
            )
            
        case .main(let user):
            MainView().environmentObject(UserManager.shared)
            // import UserManger
        }
    }
}

#Preview {
    RootView()
}
