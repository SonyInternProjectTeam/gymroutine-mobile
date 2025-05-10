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
    private let analyticsService = AnalyticsService.shared
    
    // フォロワーとフォロー中の一覧画面に遷移するための状態変数
    @State private var showFollowers: Bool = false
    @State private var showFollowing: Bool = false
    @State private var showEditProfile: Bool = false

    let router: Router?

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
            // iOS 17 이상 대응 onChange 수정
            .onChange(of: viewModel.selectedPhotoItem) {
                viewModel.handleSelectedPhotoItemChange(viewModel.selectedPhotoItem)
            }
            .navigationDestination(isPresented: $showEditProfile) {
                if let user = viewModel.user, let router = router {
                    ProfileEditView(user: user, router: router)
                }
            }
            .onAppear {
                // Only load user data if the viewModel's user is not already set
                // This prevents overwriting the profile when navigating from followers/following list
                if viewModel.user == nil {
                    viewModel.loadUserData()
                } else {
                    // Always refresh workouts when view appears
                    Task {
                        await viewModel.fetchWorkouts()
                    }
                }
                
                // Add observer for workout deletion notification
                NotificationCenter.default.addObserver(
                    forName: .workoutDeleted,
                    object: nil,
                    queue: .main
                ) { _ in
                    // Refresh workouts when notification is received
                    Task {
                        await viewModel.fetchWorkouts()
                    }
                }
                
                // Log screen view
                analyticsService.logScreenView(screenName: "Profile")
            }
            .onDisappear {
                // Remove the observer when the view disappears
                NotificationCenter.default.removeObserver(self, name: .workoutDeleted, object: nil)
            }
        }
    }
    
    // MARK: - Private Helper Views
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
                    AnalyticsView()
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
        ProfileView(viewModel: ProfileViewModel(user: User(uid: "previewUser1", email: "preview@example.com", name: "Preview Useraaaaa")), router: Router())
    }
}

