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
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView(viewModel: HomeViewModel())
                }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
                
                NavigationStack {
                    CalendarView()
                }
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
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
                    ProfileView(viewModel: ProfileViewModel())
                }
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
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
        }
        .sheet(isPresented: Binding<Bool>(
            get: { workoutManager.isWorkoutSessionActive && workoutManager.isWorkoutSessionMaximized },
            set: { newValue in
                if !newValue && workoutManager.isWorkoutSessionActive {
                    workoutManager.minimizeWorkoutSession()
                }
            }
        )) {
            if let sessionViewModel = workoutManager.workoutSessionViewModel {
                WorkoutSessionView(
                    viewModel: sessionViewModel,
                    onEndWorkout: {
                        workoutManager.endWorkout()
                    }
                )
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(false)
                .onDisappear {
                    if workoutManager.isWorkoutSessionActive {
                        workoutManager.minimizeWorkoutSession()
                    }
                }
            }
        }
    }
}
