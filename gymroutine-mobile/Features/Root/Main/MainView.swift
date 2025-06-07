//
//  MainView.swift
//  gymroutine-mobile
//
//  Created by SATTSAT on 2024/12/26
//

import SwiftUI

struct MainView: View {
    
    @ObservedObject var workoutManager = AppWorkoutManager.shared
    @ObservedObject private var userManager = UserManager.shared
    @State private var selectedTab = 0
    @State private var showingTermsForExistingUser = false
    let router: Router
    private let analyticsService = AnalyticsService.shared
    
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
                    ProfileView(router: router)
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
        .sheet(isPresented: $showingTermsForExistingUser) {
            TermsOfServiceView {
                // Terms agreed, update user's agreement status
                Task {
                    let success = await UserService.shared.updateTermsAgreement()
                    if success {
                        await MainActor.run {
                            userManager.hasAgreedToTerms = true
                            UIApplication.showBanner(type: .success, message: "利用規約への同意が完了しました")
                        }
                    }
                }
            }
        }
        .onAppear {
            // Check if existing user hasn't agreed to terms
            checkTermsAgreement()
            analyticsService.logScreenView(screenName: "Main")
        }
        .onChange(of: userManager.currentUser) { _, _ in
            // Check terms agreement when user changes
            checkTermsAgreement()
        }
    }
    
    private func checkTermsAgreement() {
        guard let user = userManager.currentUser else { return }
        
        // If user hasn't agreed to terms, show terms modal
        if user.hasAgreedToTerms != true && !showingTermsForExistingUser {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showingTermsForExistingUser = true
            }
        }
    }
}

