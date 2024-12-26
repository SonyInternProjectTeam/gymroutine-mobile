//
//  InitProfileSetupView.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2024/12/26
//  
//

import SwiftUI

struct InitProfileSetupView: View {
    
    @ObservedObject var viewModel: InitProfileSetupViewModel
    
    var body: some View {
        Text("ユーザー初期設定")
    }
}

#Preview {
    InitProfileSetupView(viewModel: InitProfileSetupViewModel(router: Router()))
}
