//
//  SplashView.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2024/12/26
//  
//

import SwiftUI

struct SplashView: View {
    
    @ObservedObject var viewModel: SplashViewModel
    
    var body: some View {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 16) {
                    if let icon = UIApplication.shared.icon {
                        Image(uiImage: icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(.rect(cornerRadius: 8))
                    }
                    
                    Text("GymLinker")
                        .font(.largeTitle.bold())
                }
                .offset(y: -16)
            }
    }
}

#Preview {
    SplashView(viewModel: SplashViewModel(router: Router()))
}
