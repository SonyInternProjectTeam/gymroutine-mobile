//
//  gymroutine_mobileApp.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/10/28.
//

import SwiftUI
import Firebase

@main
struct gymroutine_mobileApp: App {
    @StateObject private var userManager = UserManager.shared
    
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userManager)
        }
    }
}
