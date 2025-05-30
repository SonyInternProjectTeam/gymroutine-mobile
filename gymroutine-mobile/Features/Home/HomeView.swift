//
//  HomeView.swift
//  gymroutine-mobile
//
//  Created by SATTSAT on 2024/12/26
//
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject private var userManager = UserManager.shared
    @ObservedObject private var workoutManager = AppWorkoutManager.shared
    private let analyticsService = AnalyticsService.shared
    
    @State private var isShowTodayworkouts = true
    @State private var createWorkoutFlg = false
    @State private var showingUpdateWeightSheet = false
    @State private var isShowingOnboarding = false
    @State private var showingNotifications = false
    @StateObject private var notificationsViewModel = NotificationsViewModel()
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        
        let appearance: UITabBarAppearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().standardAppearance = appearance
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            header
            
            VStack(spacing: 24) {
                calendarBox
                todaysWorkoutsBox
                    .onAppear {
                        viewModel.loadTodaysWorkouts()
                    }
                userInfoBox
            }
            .padding()
        }
        .padding(.top, 8)
        .background(Color.gray.opacity(0.1))
        .contentMargins(.top, 16)
        .contentMargins(.bottom, 80)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingNotifications = true
                    // Log notification button tap
                    analyticsService.logUserAction(
                        action: "notifications_button_tapped",
                        contentType: "home_view"
                    )
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        // 읽지 않은 알림 개수 표시
                        if notificationsViewModel.unreadNotificationsCount > 0 {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 16, height: 16)
                                
                                Text("\(min(notificationsViewModel.unreadNotificationsCount, 99))")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .offset(x: 6, y: -6)
                        }
                    }
                }
            }
        }
        .refreshable {
            // 스크롤 당겨서 새로고침 시 스토리 데이터 업데이트
            viewModel.refreshStories()
            // 기타 필요한 데이터 업데이트
            viewModel.loadFollowingUsers()
            viewModel.loadTodaysWorkouts()
            // 히트맵 데이터도 업데이트
            viewModel.loadHeatmapData()
            // 알림 데이터도 업데이트
            notificationsViewModel.loadAllNotifications()
        }
        .sheet(isPresented: $showingUpdateWeightSheet) {
            UpdateWeightView()
                .environmentObject(userManager)
        }
        .sheet(item: $viewModel.selectedUserForStory) { user in
            StoryView(viewModel: StoryViewModel(user: user, stories: viewModel.storiesForSelectedUser))
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView()
                .onDisappear {
                    // 알림 화면이 닫힐 때 알림 데이터 새로고침
                    notificationsViewModel.loadAllNotifications()
                }
        }
        .fullScreenCover(isPresented: $createWorkoutFlg) {
            CreateWorkoutView()
                .onDisappear {
                    viewModel.loadTodaysWorkouts()
                }
        }
        .overlay(alignment: .bottom) {
            buttonBox
                .clipped()
                .shadow(radius: 4)
                .padding()
        }
        .onAppear {
            // Log screen view event
            analyticsService.logScreenView(screenName: "Home")
            // 알림 데이터 로드
            notificationsViewModel.loadAllNotifications()
        }
    }
    
    private var header: some View {
        VStack(spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // 현재 사용자 프로필 이미지 및 이름 표시 (항상 맨 왼쪽에 표시)
                    if let currentUser = userManager.currentUser {
                        let hasActiveStory = viewModel.userHasActiveStory(userId: currentUser.uid)
                        let isActive = viewModel.activeFollowingUsers.contains(where: { $0.uid == currentUser.uid })
                        
                        // 현재 사용자는 항상 표시
                        FollowingUserIcon(user: currentUser, hasActiveStory: hasActiveStory, isActive: isActive)
                            .onTapGesture {
                                viewModel.showStories(for: currentUser)
                            }
                    }
                    
                    // 팔로우 중인 사용자들 중 스토리가 있거나 활동 중인 사용자만 표시
                    ForEach(viewModel.followingUsers, id: \.uid) { user in
                        let hasActiveStory = viewModel.userHasActiveStory(userId: user.uid)
                        let isActive = viewModel.activeFollowingUsers.contains(where: { $0.uid == user.uid })
                        
                        if hasActiveStory || isActive {
                            FollowingUserIcon(
                                user: user, 
                                hasActiveStory: hasActiveStory,
                                isActive: isActive
                            )
                            .onTapGesture {
                                viewModel.showStories(for: user)
                            }
                        }
                    }
                }
            }
            .contentMargins(.vertical, 4)
            .contentMargins(.horizontal, 16)
            
            // Display count of active users
            if !viewModel.activeFollowingUsers.isEmpty {
                Label("現在\(viewModel.activeFollowingUsers.count)名が筋トレしています！", systemImage: "flame")
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .hAlign(.leading)
                    .background(Color.red.gradient)
            }

            Divider().padding(.bottom, 5)
        }
        .onAppear {
            viewModel.setupActiveUsersRealTimeListener()
            viewModel.forceCheckActiveUsers()
        }
    }
    
    private var calendarBox: some View {
        HeatmapCalendarView(heatmapData: viewModel.heatmapData, startDate: Date(), numberOfMonths: 1)
            .frame(height: 230)
            .padding(.bottom, 20)
            .onAppear {
                // Log calendar viewed event
                analyticsService.logEvent("calendar_viewed")
            }
            .onTapGesture {
                // Log heatmap interaction when user taps on the calendar
                analyticsService.logEvent("heatmap_interaction", parameters: [
                    "interaction_type": "tap"
                ])
            }
    }

    private var todaysWorkoutsBox: some View {
        VStack {
            Button {
                withAnimation {
                    isShowTodayworkouts.toggle()
                    
                    // Log toggle today's workouts
                    analyticsService.logUserAction(
                        action: "toggle_todays_workouts",
                        contentType: "home_view"
                    )
                }
            } label: {
                HStack {
                    Text("今日のワークアウト")
                        .font(.title2.bold())
                    
                    Image(systemName: "chevron.right")
                        .fontWeight(.semibold)
                        .rotationEffect(.degrees(isShowTodayworkouts ? 90 : 0))
                }
                .hAlign(.leading)
            }
            .foregroundStyle(.primary)
            
            if isShowTodayworkouts {
                if viewModel.todaysWorkouts.isEmpty {
                    Text("今日のワークアウトはありません")
                        .padding()
                } else {
                    ForEach(viewModel.todaysWorkouts, id: \.id) { workout in
                        NavigationLink {
                            WorkoutDetailView(viewModel: WorkoutDetailViewModel(workout: workout))
                                .onAppear {
                                    // Log todays workout selection
                                    analyticsService.logUserAction(
                                        action: "select_todays_workout",
                                        itemId: workout.id ?? "",
                                        itemName: workout.name,
                                        contentType: "home_view"
                                    )
                                }
                        } label: {
                            WorkoutCell(
                                workoutName: workout.name,
                                exerciseImageName: workout.exercises.first?.key,
                                count: workout.exercises.count
                            )
                        }
                        .buttonStyle(PlainButtonStyle()) // 기본 네비게이션 스타일 제거
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private var userInfoBox: some View {
        VStack {
            if let user = userManager.currentUser {
                Text("\(user.name)の情報")
                    .font(.title2.bold())
                    .hAlign(.leading)

                HStack {
                    // Total Days
                    VStack(spacing: 16) {
                        Text("累計トレーニング日数")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .hAlign(.leading)
                        
                        HStack(alignment: .bottom) {
                            Text("\(user.totalWorkoutDays ?? 0)")
                                .font(.largeTitle.bold())
                            Text("日")
                        }
                        .hAlign(.trailing)
                    }
                    .padding()
                    .frame(height: 108)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Current Weight - Add onTapGesture here
                    VStack(spacing: 16) {
                        Text("現在の体重")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .hAlign(.leading)
                            
                        HStack(alignment: .bottom) {
                            Text(user.currentWeight != nil ? String(format: "%.1f", user.currentWeight!) : "--")
                                .font(.largeTitle.bold())
                            
                            if user.currentWeight != nil {
                                Text("kg")
                            }
                        }
                        .hAlign(.trailing)
                    }
                    .padding()
                    .frame(height: 108)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingUpdateWeightSheet = true
                        
                        // Log weight update tap
                        analyticsService.logUserAction(
                            action: "update_weight_tap",
                            contentType: "user_profile"
                        )
                    }
                }
            } else {
                Text("ユーザー情報が読み込めません")
            }
        }
    }
    
    // Workout Quick Start function
    // Todo: refactor this function to use the new workout creation flow
    private func startQuickWorkout() {
        guard let userId = userManager.currentUser?.uid else {
            print("[ERROR] Quick start failed: User ID not available")
            return
        }
        
        // Create a quick workout with an empty exercise list
        let quickWorkout = Workout(
            id: UUID().uuidString,
            userId: userId,
            name: "Quick Start",
            createdAt: Date(),
            notes: "「今すぐ始める」から作成されました。",
            isRoutine: false,
            scheduledDays: [],
            exercises: [] // Empty exercise list
        )
        
        // Log workout started analytics event
        analyticsService.logWorkoutStarted(
            workoutId: quickWorkout.id ?? "",
            workoutName: quickWorkout.name,
            isRoutine: quickWorkout.isRoutine,
            exerciseCount: quickWorkout.exercises.count
        )
        
        // Start the workout through AppWorkoutManager
        workoutManager.startWorkout(workout: quickWorkout)
        
        print("[INFO] Quick start workout created with empty exercise list")
    }
    
    private var buttonBox: some View {
        HStack {
            Button {
                // Log user action for creating routine
                analyticsService.logUserAction(
                    action: "create_routine_tapped",
                    contentType: "home_screen"
                )
                createWorkoutFlg.toggle()
            } label: {
                Label("ワークアウト作成", systemImage: "plus")
            }
            .buttonStyle(SecondaryButtonStyle())
            
            Button {
                // Log user action before starting quick workout
                analyticsService.logUserAction(
                    action: "quick_start_tapped",
                    contentType: "home_screen"
                )
                startQuickWorkout()
            } label: {
                Label("今すぐ始める", systemImage: "play")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
}

// MARK: - Subviews

struct FollowingUserIcon: View {
    let user: User
    let hasActiveStory: Bool
    let isActive: Bool
    
    init(user: User, hasActiveStory: Bool, isActive: Bool = false) {
        self.user = user
        self.hasActiveStory = hasActiveStory
        self.isActive = isActive
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                ProfileIcon(profileUrl: user.profilePhoto, size: .medium1)
                    .overlay(
                        Circle()
                            .stroke(hasActiveStory ? .main : .clear, lineWidth: 4)
                    )
                
                // Flame icon for active users
                if isActive {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.orange.gradient)
                        .padding(8)
                        .background(Circle().fill(.main))
                        .offset(x: 4, y: 4)
                }
            }
            
            // User name
            Text(user.name)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(width: 70)
        }
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel())
        .environmentObject(UserManager.shared)
}
