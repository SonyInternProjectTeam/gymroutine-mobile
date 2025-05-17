//
//  MainView.swift
//  gymroutine-mobile
//
//  Created by SATTSAT on 2024/12/26
//

import SwiftUI

struct MainView: View {
    
    @ObservedObject var workoutManager = AppWorkoutManager.shared
    @State private var selectedTab = 0
    let router: Router
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView(viewModel: HomeViewModel())
                }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }
                .tag(0)
                
                NavigationStack {
                    CalendarView()
                }
                .tabItem {
                    Image(systemName: "calendar")
                    Text("カレンダー")
                }
                .tag(1)
                
                NavigationStack {
                    SnsView()
                }
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("SNS")
                }
                .tag(2)
                
                NavigationStack {
                    ProfileView(viewModel: ProfileViewModel(), router: router)
                }
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("プロフィール")
                }
                .tag(3)
            }
            
            // ボトムタブバーの上にミニUIを配置（タブバーを隠さず上に表示）
            VStack {
                Spacer()
                if workoutManager.isWorkoutSessionActive && !workoutManager.isWorkoutSessionMaximized {
                    MiniWorkoutView()
                        .transition(.move(edge: .bottom))
                        .padding(.bottom, 49) // タブバーの高さ
                }
            }

            // Add GlobalWorkoutSessionView to manage session and result modals
            GlobalWorkoutSessionView()
        }
    }
}

