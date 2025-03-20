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
        Text("ジムルーティーン")
            .font(.largeTitle)
    }
}

#Preview {
    SplashView(viewModel: SplashViewModel(router: Router()))
}
