//
//  MainView.swift
//  gymroutine-mobile
//
//  Created by SATTSAT on 2024/12/26
//

import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel
    @ObservedObject var homeViewModel: HomeViewModel  // 변수 이름 소문자 사용
    @EnvironmentObject var userManager: UserManager
    @State private var selectedTab: Int = 0 // 현재 선택된 탭

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home 탭: NavigationStack으로 감싸서 내부 네비게이션을 지원
            NavigationStack {
                HomeView(viewModel: homeViewModel)
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(0)
            
            // Calendar 탭
            NavigationStack {
                CalendarView()
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }
            .tag(1)
            
            // SNS 탭
            NavigationStack {
                SnsView()
            }
            .tabItem {
                Label("SNS", systemImage: "magnifyingglass")
            }
            .tag(2)
            
            // Profile 탭
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle")
            }
            .tag(3)
        }
    }
}

