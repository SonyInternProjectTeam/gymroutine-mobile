//
//  MainView.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2024/12/26
//  
//

import SwiftUI

struct MainView: View {
    
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        Text("メインViewだよ")
    }
}

#Preview {
    MainView(viewModel: MainViewModel(router: Router()))
}
