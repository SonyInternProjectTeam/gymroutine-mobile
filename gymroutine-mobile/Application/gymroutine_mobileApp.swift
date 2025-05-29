//
//  gymroutine_mobileApp.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/10/28.
//

import SwiftUI
import Firebase
import FirebaseAnalytics
import FirebaseCore

@main
struct gymroutine_mobileApp: App {
    @StateObject private var userManager = UserManager.shared
    @StateObject private var authService = AuthService()
    private let analyticsService = AnalyticsService.shared
    
    init() {
        // Firebase initialization
        FirebaseApp.configure()
        
        // Analytics setup
        setupAnalytics()
        
        // UserManager and Analytics connection
        setupUserAnalyticsObserver()
        
        print("Firebase and Analytics initialized")
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .onAppear {
                    // app opened event logging
                    analyticsService.logEvent("app_opened", parameters: [
                        "timestamp": Date().timeIntervalSince1970
                    ])
                    
                    // if there is a logged in user, set user ID in Analytics
                    if let currentUser = userManager.currentUser {
                        analyticsService.setUserId(currentUser.uid)
                        analyticsService.setUserProperty(name: "user_name", value: currentUser.name)
                        print("existing logged in user ID \(currentUser.uid) is set in Analytics")
                    }
                }
        }
    }
    
    private func setupAnalytics() {
        // Analytics collection enabled (default is true)
        Analytics.setAnalyticsCollectionEnabled(true)
        
        #if DEBUG
        // Enable Analytics logging in debug mode
        // setLogLevel is not directly provided - use Firebase Console's DebugView instead
        print("Firebase Analytics debug mode: To see DebugView, connect to Firebase Console")
        #endif
    }
    
    private func setupUserAnalyticsObserver() {
        // Detect changes in UserManager's currentUser and set user ID in Analytics
        NotificationCenter.default.addObserver(forName: NSNotification.Name("UserLoggedIn"), object: nil, queue: .main) { [self] notification in
            if let user = notification.object as? User {
                // Set user ID in Analytics
                analyticsService.setUserId(user.uid)
                
                // user property setting
                analyticsService.setUserProperty(name: "user_name", value: user.name)
                
                print("사용자 ID \(user.uid)를 Analytics에 설정했습니다.")
            }
        }
        
        // logout process
        NotificationCenter.default.addObserver(forName: NSNotification.Name("UserLoggedOut"), object: nil, queue: .main) { _ in
            // remove user ID
            analyticsService.setUserId(nil)
            print("Analytics에서 사용자 ID를 제거했습니다.")
        }
    }
}
