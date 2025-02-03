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
                if let newItem = newItem,
                   let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.uploadProfilePhoto(image)
                }
            }
        }
    }
    
    private func profileHeader(user: User) -> some View {
        VStack(spacing: 16) {
            ZStack {
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
                
                // PhotosPicker (프로필 사진 변경)
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
            
            Text(user.name)
                .font(.title)
                .fontWeight(.bold)
            
            if let birthday = user.birthday {
                // 예시: 생일로 나이 계산 (여기서는 간단하게 연도만 비교)
                let age = Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 0
                Text("\(age)歳 \(user.gender)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
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
            
            // 내 프로필이면 편집 버튼, 다른 사람의 프로필이면 팔로우 버튼 표시
            if viewModel.isCurrentUser {
                Button(action: {
                    // 프로필 편집 화면으로 이동하는 동작 추가
                    print("프로필 편집 버튼 탭")
                }) {
                    Text("プロフィール編集")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 32)
            } else {
                Button(action: {
                    if viewModel.isFollowing {
                        viewModel.unfollow()
                    } else {
                        viewModel.follow()
                    }
                }) {
                    Text(viewModel.isFollowing ? "フォロー中" : "フォローする")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(viewModel.isFollowing ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 32)
            }
        }
    }
}
