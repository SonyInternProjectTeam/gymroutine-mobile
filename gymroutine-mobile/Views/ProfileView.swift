//
//  ProfileView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/12/27.
//

import Foundation
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager

    var body: some View {
        VStack {
            if let user = userManager.currentUser {
                Text("Name: \(user.name)")
                    .font(.title2)
                Text("Email: \(user.email)")
                    .font(.body)
            } else {
                Text("プロフィール情報がありません")
            }
        }
        .padding()
        .navigationTitle("Profile")
    }
}
