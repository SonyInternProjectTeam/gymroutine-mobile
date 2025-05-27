//
//  SnsView.swift
//  gymroutine-mobile
//
//  Created by 森祐樹 on 2024/12/30.
//

import SwiftUI

struct SnsView: View {
    @StateObject private var viewModel = SnsViewModel()
    @FocusState private var isFocused: Bool
    @State private var searchMode: Bool = false
    @State private var showingNotifications = false
    private let analyticsService = AnalyticsService.shared

    var body: some View {
        VStack(spacing: 0) {
            searchBarView

            Divider()

            if searchMode {
                searchResultsView
            }
            else {
                ScrollView {
                    recommendedUsersView
                    
                    Divider()
                        .padding(.vertical, 16)
                    
                    groupsView
                    
                    Divider()
                        .padding(.vertical, 16)
                    
                    workoutTemplatesView
                }
            }
        }
        .onChange(of: isFocused) {
            // サーチモードOFFのときにフォーカスON → サーチモードON
            withAnimation {
                if !searchMode && isFocused { searchMode = true }
            }
        }
        .navigationTitle("SNS")
        // Large Title을 쓰지 않고 상단 여백을 줄이려면 Inline Title
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingNotifications) {
            NotificationsView()
        }
        .onAppear {
            // 画面表示時におすすめユーザーを생성하고 취득
            viewModel.initializeRecommendations()
            
            // 그룹 목록 조회
            viewModel.fetchUserGroups()
            
            // Log screen view
            analyticsService.logScreenView(screenName: "Sns")
        }
    }

    private var searchBarView: some View {
        HStack(spacing: 8) {
            UserSearchField(text: $viewModel.searchName, onSubmit: {
                viewModel.fetchUsers()
            })
            .focused($isFocused)

            if searchMode {
                Button("キャンセル") {
                    // NavigationStack을 닫음
                    withAnimation {
                        isFocused = false
                        searchMode = false
                        viewModel.searchName = ""
                        viewModel.lastSearchedName = ""
                        viewModel.userDetails = []
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var searchResultsView: some View {
        Group {
            // 검색 결과 / 오류 / 결과 없음 표시
            if let errorMessage = viewModel.errorMessage {
                Text("\(errorMessage)")
                    .foregroundColor(.secondary)
                    .padding()
                    .vAlign(.top)
            } else if viewModel.userDetails.isEmpty && !viewModel.lastSearchedName.isEmpty {
                Text("「\(viewModel.lastSearchedName)」に一致するユーザーがいません")
                    .foregroundColor(.secondary)
                    .padding()
                    .vAlign(.top)
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.userDetails, id: \.uid) { user in
                            NavigationLink {
                                ProfileView(viewModel: ProfileViewModel(user: user), router: nil)
                            } label: {
                                UserCell(user: user)
                            }
                        }
                    }
                }
            }
        }
        .contentMargins(.top, 16)
    }

    private var recommendedUsersView: some View {
        // 추천 사용자 영역
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "person.2")
                Text("おすすめユーザー")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    // おすすめリストを更新
                    viewModel.refreshRecommendations()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.headline)
                }
                .disabled(viewModel.isLoadingRecommendations)
            }
            .padding(.horizontal, 16)
            
            if viewModel.isLoadingRecommendations {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if let error = viewModel.recommendationsError {
                Text(error)
                    .hAlign(.center)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .padding(.horizontal, 16)
            } else if viewModel.recommendedUsers.isEmpty {
                VStack(alignment: .center) {
                    Text("おすすめユーザーが見つかりませんでした")
                        .foregroundColor(.gray)
                        .padding()
                    
                    Button("再取得") {
                        viewModel.refreshRecommendations()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 30)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.recommendedUsers) { recommendedUser in
                            RecommendedUserCell(user: recommendedUser.user)
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 8)
                    .padding(.vertical,8)
                }
            }
        }
        .padding(.top, 16)
    }
    
    private var groupsView: some View {
        // 그룹 영역
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "person.3")
                Text("グループ")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                HStack(spacing: 12) {
                    NavigationLink(destination: GroupSearchView()) {
                        Image(systemName: "magnifyingglass")
                            .font(.headline)
                    }
                    
                    NavigationLink(destination: GroupManagementView()) {
                        Image(systemName: "plus.circle")
                            .font(.headline)
                    }
                }
            }
            .padding(.horizontal, 16)
            
            if viewModel.isLoadingGroups {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if let error = viewModel.groupsError {
                Text(error)
                    .hAlign(.center)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .padding(.horizontal, 16)
            } else if viewModel.userGroups.isEmpty {
                VStack(alignment: .center) {
                    Text("参加しているグループがありません")
                        .foregroundColor(.gray)
                        .padding()
                    
                    NavigationLink("グループを探す", destination: GroupSearchView())
                        .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 30)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.userGroups) { group in
                            NavigationLink(destination: GroupDetailView(group: group)) {
                                GroupCell(groupCell: group)
                            }
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 8)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.top, 16)
    }
    
    private var workoutTemplatesView: some View {
        // 워크아웃 템플릿 영역
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "figure.run")
                Text("おすすめトレーニング")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    // 템플릿 새로고침
                    viewModel.refreshTemplates()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.headline)
                }
                .disabled(viewModel.isLoadingTemplates)
            }
            .padding(.horizontal, 16)
            
            if viewModel.isLoadingTemplates {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if let error = viewModel.templatesError {
                Text(error)
                    .hAlign(.center)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .padding(.horizontal, 16)
            } else if viewModel.workoutTemplates.isEmpty {
                VStack(alignment: .center) {
                    Text("おすすめトレーニングが見つかりませんでした")
                        .foregroundColor(.gray)
                        .padding()
                    
                    Button("再取得") {
                        viewModel.refreshTemplates()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 30)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.workoutTemplates) { template in
                        NavigationLink(destination: TemplateDetailView(template: template)) {
                            WorkoutTemplateCell(template: template)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    /// 프로필 이미지 뷰
    private func profileImageView(for user: User) -> some View {
        Group {
            if !user.profilePhoto.isEmpty, let url = URL(string: user.profilePhoto) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
                    .clipShape(Circle())
            }
        }
    }
}

#Preview {
    NavigationStack {
        SnsView()
    }
}
