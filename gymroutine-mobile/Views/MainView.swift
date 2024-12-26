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
        VStack {
            Text("\(viewModel.user.name)でログインしました！")
                .font(.headline)
            
            Button{
                viewModel.logout()
            } label: {
                Text("ログアウトするよ")
            }
        }
    }
}

#Preview {
    MainView(
        viewModel: MainViewModel(
            router: Router(),
            user: User(uid: "qwerty12345", email: "test@example.com")))
}
