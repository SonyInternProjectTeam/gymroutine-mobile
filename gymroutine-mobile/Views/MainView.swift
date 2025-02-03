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
        NavigationView {
            TabView {
                HomeView(viewModel: viewModel)
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(0)
                
                CalendarView()
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .tag(1)
                
                SnsView()
                    .tabItem {
                        Label("SNS", systemImage: "magnifyingglass")
                    }
                    .tag(2)
                
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.circle")
                    }
                    .tag(3)
            }
        }
    }
}
