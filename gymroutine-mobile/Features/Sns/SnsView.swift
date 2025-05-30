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

    var body: some View {
        VStack(spacing: 0) {
            searchBarView

            Divider()

            if searchMode {
                searchResultsView
            }
            else {
                ScrollView {
                    VStack(spacing: 8) {
                        
                        recommendedUsersBox
                        
                        Divider()
                        
                        groupsBox
                        
                        Divider()
                        
                        workoutTemplatesBox
                    }
                }
                .contentMargins(.bottom, 24)
            }
        }
        .background(.gray.opacity(0.05))
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
        .onAppear(perform: viewModel.onAppear)
        .onReceive(NotificationCenter.default.publisher(for: AppConstants.NotificationNames.didJoinGroup)) { _ in
            // 그룹 가입 성공 시 그룹 목록 새로고침
            viewModel.fetchUserGroups()
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
        .background()
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
                                ProfileView(user: user, router: nil)
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
    
    private var recommendedUsersBox: some View {
        VStack(spacing: 0) {
            HStack {
                Label("おすすめユーザー", systemImage: "person.2")
                    .font(.title2.bold())
                
                Spacer()
                
                Button(action: {
                    viewModel.refreshRecommendations()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.headline)
                }
                .disabled(viewModel.isLoadingRecommendations)
            }
            .padding()
            
            if viewModel.isLoadingRecommendations {
                skeletonCells
            } else if let error = viewModel.recommendationsError {
                Text(error)
                    .font(.headline)
                    .foregroundColor(.red)
                    .padding(24)
            } else if viewModel.recommendedUsers.isEmpty {
                VStack(alignment: .center, spacing: 16) {
                    Text("おすすめユーザーが見つかりませんでした")
                        .foregroundColor(.secondary)
                    
                    Button("再取得") {
                        viewModel.refreshRecommendations()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(24)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.recommendedUsers) { recommendedUser in
                            RecommendedUserCell(user: recommendedUser.user)
                        }
                    }
                }
                .contentMargins(.vertical, 4)
                .contentMargins(.horizontal, 12)
            }
        }
    }
    
    private var groupsBox: some View {
        VStack(spacing: 0) {
            HStack {
                Label("グループ", systemImage: "person.3")
                    .font(.title2.bold())
                
                Spacer()
                
                HStack(spacing: 12) {
                    NavigationLink(destination: GroupSearchView()) {
                        Image(systemName: "magnifyingglass")
                            
                    }
                    
                    NavigationLink(destination: GroupManagementView()) {
                        Image(systemName: "plus.circle")
                    }
                }
                .font(.headline)
            }
            .padding()
            
            if viewModel.isLoadingGroups {
                skeletonCells
            } else if let error = viewModel.groupsError {
                Text(error)
                    .font(.headline)
                    .foregroundColor(.red)
                    .padding(24)
            } else if viewModel.userGroups.isEmpty {
                VStack(alignment: .center, spacing: 16) {
                    Text("参加しているグループがありません")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    NavigationLink("グループを探す", destination: GroupSearchView())
                        .buttonStyle(.bordered)
                }
                .padding(24)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.userGroups) { group in
                            NavigationLink(destination: GroupDetailView(group: group)) {
                                GroupCell(groupCell: group)
                            }
                        }
                    }
                }
                .contentMargins(.vertical, 4)
                .contentMargins(.horizontal, 12)
            }
        }
    }
    
    private var skeletonCells: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.init(gray: 0.8, alpha: 1.0)))
                        .frame(width: 140, height: 160)
                        .blinking(duration: 0.75)
                }
            }
        }
        .contentMargins(.vertical, 4)
        .contentMargins(.horizontal, 12)
    }
    
    private var workoutTemplatesBox: some View {
        VStack(spacing: 0) {
            HStack {
                Label("テンプレート", systemImage: "figure.run")
                    .font(.title2.bold())
                
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
            .padding()
            
            if viewModel.isLoadingTemplates {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.init(gray: 0.8, alpha: 1.0)))
                    .aspectRatio(16/9, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .blinking(duration: 0.75)
                    .padding()
            } else if let error = viewModel.templatesError {
                Text(error)
                    .font(.headline)
                    .foregroundColor(.red)
                    .padding(24)
            } else if viewModel.workoutTemplates.isEmpty {
                VStack(alignment: .center, spacing: 16) {
                    Text("おすすめトレーニングが見つかりませんでした")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Button("再取得") {
                        viewModel.refreshTemplates()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(24)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.workoutTemplates) { template in
                        NavigationLink(destination: TemplateDetailView(template: template)) {
                            WorkoutTemplateCell(template: template)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SnsView()
    }
}
