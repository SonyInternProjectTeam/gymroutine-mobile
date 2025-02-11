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
            viewModel.handleSelectedPhotoItemChange(newItem)
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
                
                // 自分のプロフィールの場合のみ、プロフィール写真変更用のボタンを表示する
                if viewModel.isCurrentUser {
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
            }
            
            Text(user.name)
                .font(.title)
                .fontWeight(.bold)
            
            if let birthday = user.birthday {
                // TODO: 生年月日から年齢を計算（ここでは単純に年数のみ計算）
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
            
            // 自分のプロフィールなら編集ボタン、他人ならフォローボタンを表示する
            if viewModel.isCurrentUser {
                Button(action: {
                    // プロフィール編集画面への遷移などを追加
                    print("プロフィール編集ボタンタップ")
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
