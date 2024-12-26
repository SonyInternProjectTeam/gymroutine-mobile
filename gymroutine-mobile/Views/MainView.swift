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
        VStack {
            
                let email = userManager.currentUser?.email
                
                Text("\(email)でログインしました！")
                    .font(.headline)
                
            

            Button {
                viewModel.logout()
            } label: {
                Text("ログアウトするよ")
            }
        }
    }
}

