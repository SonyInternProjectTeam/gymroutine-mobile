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
    @Namespace var namespace

    var body: some View {
        Group {
            if let user = viewModel.user {
                profileContentView(user: user)
            } else {
                Text("プロフィール情報がありません")
                    .font(.headline)
            }
        }
        .navigationTitle("プロフィール")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.selectedPhotoItem) { newItem in
            viewModel.handleSelectedPhotoItemChange(newItem)
        }
    }

    private func profileContentView(user: User) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                profileHeader(user: user)

                profileTabBar()
            }
        }
        .ignoresSafeArea(edges: [.top])

    }

    private func profileHeader(user: User) -> some View {
        VStack(spacing: 16) {
            HStack(alignment: .bottom, spacing: 10) {
                profileIcon(profileUrl: user.profilePhoto)
                    .padding(.vertical, 6)

                followStatsView()
            }
            .padding(.horizontal, 8)
            .frame(height: 280, alignment: .bottom)
            .background(LinearGradient(gradient: Gradient(stops: [.init(color: .gray, location: 0.0),
                                                                  .init(color: .white, location: 0.75),
                                                                  .init(color: .white, location: 1.0)]),
                                       startPoint: .top,
                                       endPoint: .bottom))

            HStack(alignment: .top, spacing: 10) {
                userBasicInfoView(user: user)

                profileActionButton()
            }
            .padding(.horizontal, 16)
        }
    }

    private func profileTabBar() -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(ProfileViewModel.ProfileTab.allCases, id: \.self) { tab in
                    Button {
                        viewModel.selectedTab = tab
                    } label: {
                        ZStack(alignment: .bottom) {
                            Text(tab.toString())
                                .accentColor(viewModel.selectedTab == tab ? .primary : .secondary)
                                .fontWeight(.semibold)
                                .padding(.vertical, 12)
                                .hAlign(.center)

                            if viewModel.selectedTab == tab {
                                Color.main
                                    .frame(width: 100, height: 2)
                                    .matchedGeometryEffect(id: "line",
                                                           in: namespace,
                                                           properties: .frame)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.horizontal, 16)
        .animation(.spring(), value: viewModel.selectedTab)
    }
}

// MARK: - profileHeader Components
extension ProfileView {
    // MARK: - HStack 上段
    private func profileIcon(profileUrl: String) -> some View {
        ZStack {
            AsyncImage(url: URL(string: profileUrl)) { image in
                image.resizable()
            } placeholder: {
                Circle()
                    .fill(Color(UIColor.systemGray2))
                    .strokeBorder(.white, lineWidth: 4)
            }
            .scaledToFill()
            .frame(width: 112, height: 112)
            .clipShape(Circle())

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
    }

    private func followStatsView() -> some View {
        HStack(spacing: 10) {
            followStatItemView(title: "フォロワー", count: viewModel.followersCount)
                .hAlign(.center)
            followStatItemView(title: "フォロー", count: viewModel.followingCount)
                .hAlign(.center)
        }
        .padding(.vertical, 16)
    }

    private func followStatItemView(title: String, count: Int) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 8))

            Text("\(count)")
                .font(.system(size: 19))
                .fontWeight(.medium)
        }
    }

    // MARK: - HStack 下段
    private func profileActionButton() -> some View {
        // 自分のプロフィールなら編集ボタン、他人ならフォローボタンを表示する
        if viewModel.isCurrentUser {
            Button(action: {
                // プロフィール編集画面への遷移などを追加
                print("プロフィール編集ボタンタップ")
            }) {
                Text("プロフィール編集")
                    .font(.headline)
            }
            .buttonStyle(CapsuleButtonStyle(color: .main))
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
            }
            .buttonStyle(CapsuleButtonStyle(color: viewModel.isFollowing ? Color.gray : Color.main))
        }
    }

    private func userBasicInfoView(user: User) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(user.name)
                .font(.system(size: 27))
                .fontWeight(.bold)

            if let birthday = user.birthday {
                // TODO: 生年月日から年齢を計算（ここでは単純に年数のみ計算）
                let age = Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 0
                Text("\(age)歳 \(user.gender)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .hAlign(.leading)
    }
}


#Preview {
    ProfileView(viewModel: ProfileViewModel())
}
