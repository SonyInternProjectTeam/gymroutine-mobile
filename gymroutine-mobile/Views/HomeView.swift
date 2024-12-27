//
//  HomeView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/12/27.
//

import Foundation
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userManager: UserManager
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        VStack {
            if let email = userManager.currentUser?.email {
                Text("\(email)でログインしました！")
                    .font(.headline)
            } else {
                Text("ユーザー情報がありません")
                    .font(.headline)
            }
            
            Button {
                viewModel.logout()
            } label: {
                Text("ログアウトするよ")
            }
        }
        .padding()
        .navigationTitle("Home")
    }
}
