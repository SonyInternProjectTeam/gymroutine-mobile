//
//  ProfileView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/12/27.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        ScrollView {
            VStack {
                if let user = viewModel.user {
                    profileHeader(user: user)
                } else {
                    Text("プロフィール情報がありません")
                        .font(.headline)
                }
            }
            .padding()
        }
        .navigationTitle("プロフィール")
    }

    private func profileHeader(user: User) -> some View {
        VStack(spacing: 16) {
            // profile image
            
            // TODO
//            AsyncImage(url: URL(string: user.profilePhoto)) { image in
//                image
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//                    .frame(width: 100, height: 100)
//                    .clipShape(Circle())
//            } placeholder: {
//                ProgressView()
//            }

            // name
            // TODO: Birthdayから歳計算必要
            Text(user.name)
                .font(.title)
                .fontWeight(.bold)

            Text("\(String(describing: user.birthday))歳 \(user.gender)")
                .font(.subheadline)
                .foregroundColor(.gray)

            // follower & following
            HStack {
                VStack {
                    Text("フォロワー")
                        .font(.subheadline)
                    Text("\(viewModel.followersCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Spacer()
                VStack {
                    Text("フォロー")
                        .font(.subheadline)
                    Text("\(viewModel.followingCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            .padding(.horizontal, 32)
        }
    }
}
