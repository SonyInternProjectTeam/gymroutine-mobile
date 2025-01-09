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
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                
                    let email = userManager.currentUser?.email
                    
                    Text("\(email)でログインしました！")
                        .font(.headline)
                    
                

                Button {
                    viewModel.logout()
                } label: {
                    Text("ログアウトするよ")
                }
                
                Text("今日のワークアウト")
                    .font(.title2.bold())
                    .hAlign(.leading)
                
                //仮表示
                ForEach(0..<2) {_ in
                    WorkoutCell()
                }
                
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}

#Preview {
    MainView(viewModel: MainViewModel(router: Router()))
        .environmentObject(UserManager.shared)
}

