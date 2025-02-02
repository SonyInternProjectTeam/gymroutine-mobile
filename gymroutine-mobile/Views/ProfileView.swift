//
//  ProfileView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/12/27.
//

import SwiftUI
import PhotosUI

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
        .onChange(of: viewModel.selectedPhotoItem) { newItem in
            Task {
                if let newItem = newItem, let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.uploadProfilePhoto(image)
                }
            }
        }
    }
    
    private func profileHeader(user: User) -> some View {
        VStack(spacing: 16) {
            ZStack {
                // ✅ 프로필 이미지 표시
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
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 100)
                }
                
                // ✅ 프로필 이미지 변경 버튼 (PhotosPicker)
                PhotosPicker(
                    selection: $viewModel.selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blue)
                        .background(Color.white)
                        .clipShape(Circle())
                        .offset(x: 35, y: 35)
                }
            }
            
            // ✅ 이름 표시
            Text(user.name)
                .font(.title)
                .fontWeight(.bold)
            
            Text("\(String(describing: user.birthday))歳 \(user.gender)")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // ✅ 팔로워 & 팔로잉
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
