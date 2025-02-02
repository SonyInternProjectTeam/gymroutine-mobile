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
            // ✅ 프로필 이미지 (URL이 유효한지 확인 후 로드)
            if let profileURL = URL(string: user.profilePhoto), !user.profilePhoto.isEmpty {
                AsyncImage(url: profileURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 100)
                }
            } else {
                // ✅ 기본 프로필 이미지
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
            }

            // ✅ 사용자 이름 및 정보
            Text(user.name)
                .font(.title)
                .fontWeight(.bold)

            Text("\(String(describing: user.birthday ?? Date()))歳 \(user.gender)")
                .font(.subheadline)
                .foregroundColor(.gray)

            // ✅ 팔로워 & 팔로잉 수 표시
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

