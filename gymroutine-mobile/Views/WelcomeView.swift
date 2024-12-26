//
//  WelcomeView.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2024/12/26
//  
//

import SwiftUI

struct WelcomeView: View {
    
    @ObservedObject var viewModel: WelcomeViewModel
    
    var body: some View {
        Text("WelcomeViewだよ")
    }
}

#Preview {
    WelcomeView(viewModel: WelcomeViewModel(router: Router()))
}
