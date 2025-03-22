//
//  ProfileView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/12/27.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Namespace var namespace
    
    // フォロワーとフォロー中の一覧画面に遷移するための状態変数
    @State private var showFollowers: Bool = false
    @State private var showFollowing: Bool = false
    
    var body: some View {
        ZStack {
            Group {
                if let user = viewModel.user {
                    profileContentView(user: user)
                } else {
                    Text("プロフィール情報がありません")
                        .font(.headline)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: viewModel.selectedPhotoItem) { newItem in
                viewModel.handleSelectedPhotoItemChange(newItem)
            }
            // 隠しNavigationLinkをoverlayで配置（影響を与えない0サイズ）
            .overlay(
                Group {
                    NavigationLink(
                        destination: FollowersListView(userID: viewModel.user?.uid ?? ""),
                        isActive: $showFollowers,
                        label: { EmptyView() }
                    )
                    NavigationLink(
                        destination: FollowingListView(userID: viewModel.user?.uid ?? ""),
                        isActive: $showFollowing,
                        label: { EmptyView() }
                    )
                }
                    .frame(width: 0, height: 0)
                    .hidden()
            )
        }
    }
    
    private func profileContentView(user: User) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                profileHeader(user: user)
                profileTabBar()
                profileDetailView()
            }
        }
        .ignoresSafeArea(edges: [.top])
        .background(Color.mainBackground)
    }
    
    private func profileHeader(user: User) -> some View {
        VStack(spacing: 16) {
            // 上段：プロフィールアイコンとフォロースタッツ
            HStack(alignment: .bottom, spacing: 10) {
                profileIcon(profileUrl: user.profilePhoto)
                    .padding(.vertical, 6)
                followStatsView()
            }
            .padding(.horizontal, 8)
            .frame(height: 280, alignment: .bottom)
            .background(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .gray, location: 0.0),
                        .init(color: .mainBackground, location: 0.75),
                        .init(color: .mainBackground, location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // 下段：ユーザー基本情報とアクションボタン
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
                            HStack(spacing: 8) {
                                Image(systemName: tab.imageName())
                                    .accentColor(viewModel.selectedTab == tab ? .primary : .secondary)
                                Text(tab.toString())
                                    .accentColor(viewModel.selectedTab == tab ? .primary : .secondary)
                                    .fontWeight(.semibold)
                            }
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
    
    private func profileDetailView() -> some View {
        Group {
            switch viewModel.selectedTab {
            case .analysis:
                Text("分析")
            case .posts:
                if viewModel.workouts.isEmpty {
                    Text("まだワークアウトがありません")
                        .padding()
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.workouts, id: \.id) { workout in
                            // WorkoutCell을 사용하여 워크아웃 정보를 표시
                            WorkoutCell(
                                workoutName: workout.name,
                                count: workout.exercises.count
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    
}

// MARK: - profileHeader Components
extension ProfileView {
    // MARK: - プロフィールアイコン部分
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
            
            // 自分のプロフィールの場合のみ、プロフィール写真変更ボタンを表示
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
    
    // MARK: - フォロースタッツ部分（フォロワー/フォローの一覧画面に遷移）
    private func followStatsView() -> some View {
        HStack(spacing: 10) {
            Button {
                print("DEBUG: フォロワーボタンタップ")
                showFollowers = true
            } label: {
                followStatItemView(title: "フォロワー", count: viewModel.followersCount)
                    .hAlign(.center)
            }
            Button {
                print("DEBUG: フォローボタンタップ")
                showFollowing = true
            } label: {
                followStatItemView(title: "フォロー", count: viewModel.followingCount)
                    .hAlign(.center)
            }
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
    
    // MARK: - プロフィールアクションボタン（編集/フォロー）
    private func profileActionButton() -> some View {
        if viewModel.isCurrentUser {
            Button(action: {
                print("DEBUG: プロフィール編集ボタンタップ")
                // プロフィール編集画面への遷移処理を追加
            }) {
                Text("プロフィール編集")
                    .font(.headline)
            }
            .buttonStyle(CapsuleButtonStyle(color: .main))
        } else {
            Button(action: {
                print("DEBUG: フォロー/フォロー解除ボタンタップ, isFollowing: \(viewModel.isFollowing)")
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
    
    // MARK: - ユーザー基本情報部分
    private func userBasicInfoView(user: User) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(user.name)
                .font(.system(size: 27))
                .fontWeight(.bold)
            if let birthday = user.birthday {
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
