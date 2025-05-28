//
//  ProfileView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/12/27.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @Namespace var namespace
    private let analyticsService = AnalyticsService.shared
    
    // フォロワーとフォロー中の一覧画面に遷移するための状態変数
    @State private var showFollowers: Bool = false
    @State private var showFollowing: Bool = false
    @State private var showEditProfile: Bool = false
    @State private var isShowSafeAreaBackground: Bool = false

    let router: Router?
    // バッテリー・時間が表示されているステータスバーの高さを取得
    private let statusBarHeight = UIApplication.shared
        .connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?
        .statusBarManager?
        .statusBarFrame.height ?? 0
    
    init(user: User? = nil, router: Router? = nil) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
        self.router = router
    }

    var body: some View {
        Group {
            if let user = viewModel.user {
                ScrollView(showsIndicators: false) {
                    ZStack(alignment: .top) {
                        profileContentView2(user: user)
                        
                        statusBarBackground()
                    }
                }
                .coordinateSpace(name: "SCROLL")
                .background(Color.mainBackground)
                .ignoresSafeArea(edges: .top)
            } else {
                Text("ユーザーが存在しません")
                    .font(.headline)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Show menu button only for other users' profiles
            if viewModel.user != nil, !viewModel.isCurrentUser {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            viewModel.blockUser()
                        } label: {
                            Label("ユーザーをブロック", systemImage: "person.fill.xmark")
                        }
                        
                        Button(role: .destructive) {
                            viewModel.reportUser()
                        } label: {
                            Label("ユーザーを警告", systemImage: "exclamationmark.triangle")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        // iOS 17 이상 대응 onChange 수정
        .onChange(of: viewModel.selectedPhotoItem) {
            viewModel.handleSelectedPhotoItemChange(viewModel.selectedPhotoItem)
        }
        .navigationDestination(isPresented: $showEditProfile) {
            if let user = viewModel.user, let router = router {
                ProfileEditView(user: user, router: router)
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }
    
    @ViewBuilder
    private func statusBarBackground() -> some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .named("SCROLL")).minY
            let opacity = min(max(-minY / (statusBarHeight * 2), 0), 1)
            
            Color.mainBackground
                .opacity(opacity)
                .offset(y: -minY)
        }
        .frame(height: statusBarHeight)
    }
    
    // MARK: - Private Helper Views
    private func profileContentView2(user: User) -> some View {
        VStack(spacing: 24) {
            profileHeader(user: user)
            
            // ブロックされたユーザーの場合、メッセージを表示
            if viewModel.isBlocked {
                VStack(spacing: 8) {
                    Image(systemName: "person.fill.xmark")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("ブロックしたユーザーです")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        viewModel.unblockUser()
                    }) {
                        Text("ブロックを解除")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.main)
                            .cornerRadius(20)
                    }
                    .padding(.top, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                profileTabBar()
                profileDetailView()
            }
        }
        .offset(y: -256)
    }
    
    private func profileHeader(user: User) -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(.gray)
                .frame(height: 256)
            
            VStack(spacing: 16) {
                // 上段：プロフィールアイコンとフォロースタッツ
                HStack(alignment: .bottom, spacing: 10) {
                    profileIcon(profileUrl: user.profilePhoto)
                        .padding(.vertical, 6)
                    followStatsView(user: user)
                }
                .padding(.horizontal, 8)
                // 上段の空白の高さを調整
                .frame(height: 220, alignment: .bottom)
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
                // WeightHistoryViewModel이 자체적으로 UserManager에서 데이터를 관찰합니다
                // WeightHistoryGraphView(weightHistory: viewModel.user?.weightHistory)
                AnalyticsView(profileOwnerId: viewModel.user?.uid)
            case .posts:
                if viewModel.workouts.isEmpty {
                    Text("まだワークアウトがありません")
                        .padding()
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.workouts, id: \.id) { workout in
                            NavigationLink(destination: WorkoutDetailView(viewModel: WorkoutDetailViewModel(workout: workout))) {
                                WorkoutCell(
                                    workoutName: workout.name,
                                    exerciseImageName: workout.exercises.first?.key,
                                    count: workout.exercises.count
                                )
                            }
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
        ZStack(alignment: .bottomTrailing) {
            ProfileIcon(profileUrl: profileUrl, size: .large)

            // 自分のプロフィールの場合のみ、プロフィール写真変更ボタンを表示
            if viewModel.isCurrentUser {
                PhotosPicker(
                    selection: $viewModel.selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Image(systemName: "pencil.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .blue)
                        .padding(8)
                }
            }
        }
    }
    
    // MARK: - フォロースタッツ部分（フォロワー/フォローの一覧画面に遷移）
    private func followStatsView(user: User) -> some View {
        HStack(spacing: 10) {
            NavigationLink {
                FollowListView(userID: user.uid, listType: .followers, router: router)
            } label: {
                VStack(spacing: 4) {
                    Text("フォロワー")
                        .font(.system(size: 8))

                    Text("\(viewModel.followersCount)") // ViewModel에서 가져옴
                        .font(.system(size: 19, weight: .medium))
                }
                .foregroundColor(.primary)
            }
            .hAlign(.center)

            NavigationLink {
                FollowListView(userID: user.uid, listType: .following, router: router)
            } label: {
                VStack(spacing: 4) {
                    Text("フォロー中")
                        .font(.system(size: 8))

                    Text("\(viewModel.followingCount)") // ViewModel에서 가져옴
                        .font(.system(size: 19, weight: .medium))
                }
                .foregroundColor(.primary)
            }
            .hAlign(.center)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - プロフィールアクションボタン（編集/フォロー）
    private func profileActionButton() -> some View {
        if viewModel.isCurrentUser {
            Button(action: {
                showEditProfile = true
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
                .lineLimit(1)
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
    NavigationStack {
        ProfileView(
            user: User(uid: "previewUser1", email: "preview@example.com", name: "Preview Useraaaaa"),
            router: Router()
        )
    }
}

