//
//  FollowListView.swift
//  gymroutine-mobile
//
//  Created by 森祐樹 on 2025/04/27.
//

import SwiftUI

/// フォロー関係（followers / following）のリストを表示するView
struct FollowListView: View {
    enum ListType {
        case followers
        case following

        var title: String {
            switch self {
            case .followers: return "フォロワー"
            case .following: return "フォロー中"
            }
        }
    }

    let userID: String
    let listType: ListType
    let router: Router?

    @State private var users: [User] = []
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    private let analyticsService = AnalyticsService.shared

    private let followService = FollowService()

    var body: some View {
        ScrollView(showsIndicators: true) {
            LazyVStack(spacing: 0) {
                if isLoading {
                    loadingView
                } else if let errorMessage = errorMessage {
                    errorView(message: errorMessage)
                } else if users.isEmpty {
                    emptyView
                } else {
                    usersListView
                }
            }
        }
        .navigationTitle(listType.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchUsers(showLoading: true)
            
            // Log screen view
            analyticsService.logScreenView(screenName: "FollowList_\(listType == .followers ? "Followers" : "Following")")
        }
        .refreshable {
            await fetchUsers(showLoading: false)
        }
    }

    @ViewBuilder
    private var loadingView: some View {
        ProgressView()
            .padding(12)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 8) {
            Text(message)
                .foregroundColor(.secondary)

            Button {
                Task {
                    await fetchUsers(showLoading: true)
                }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
        }
        .padding(.vertical, 36)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .resizable()
                .scaledToFit()
                .frame(height: 100)

            Text("まだ\(listType == .followers ? "フォロワー" : "フォロー中のユーザー")がいません")
        }
        .foregroundStyle(.secondary)
        .padding(.vertical, 36)
    }

    private var usersListView: some View {
        ForEach(users, id: \.uid) { user in
            NavigationLink(destination: ProfileView(viewModel: ProfileViewModel(user: user), router: nil)) {
                UserCell(user: user)
            }
        }
    }

    private func fetchUsers(showLoading: Bool) async {
        if showLoading {
            isLoading = true
        }
        errorMessage = nil

        print("DEBUG: Fetching \(listType) list for userID: \(userID)")

        let result: Result<[User], Error>

        switch listType {
        case .followers:
            result = await followService.getFollowers(for: userID)
        case .following:
            result = await followService.getFollowing(for: userID)
        }

        switch result {
        case .success(let users):
            print("DEBUG: Successfully fetched users: \(users.map { $0.name })")
            self.users = users
        case .failure(let error):
            print("ERROR: Failed to fetch users: \(error.localizedDescription)")
            self.errorMessage = "データの取得に失敗しました"
        }

        isLoading = false
    }
}


#Preview {
    NavigationStack {
        FollowListView(userID: "AhGAfsGPU8cwvsONT2duSFcQGdJ2", listType: .followers, router: nil)
    }
}

#Preview {
    NavigationStack {
        FollowListView(userID: "AhGAfsGPU8cwvsONT2duSFcQGdJ2", listType: .following, router: nil)
    }
}
