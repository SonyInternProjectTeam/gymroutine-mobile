//
//  FollowersListView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/03/01.
//

import SwiftUI

struct FollowersListView: View {
    let userID: String
    let router: Router?
    @State private var followers: [User] = []
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    private let followService = FollowService()

    var body: some View {
        ScrollView(showsIndicators: true) {
            LazyVStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .padding(12)
                } else {
                    if let errorMessage = errorMessage {
                        errorView(message: errorMessage)
                    } else if followers.isEmpty {
                        emptyView
                    } else {
                        followersListView
                    }
                }
            }
        }
        .navigationTitle("フォロワー")
        .task {
            await fetchFollowers(showLoading: true)
        }
        .refreshable {
            await fetchFollowers(showLoading: false)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 8) {
            Text(message)
                .foregroundColor(.secondary)

            Button {
                Task {
                    await fetchFollowers(showLoading: true)
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

            Text("まだフォロワーがいません")
        }
        .foregroundStyle(.secondary)
        .padding(.vertical, 36)
    }

    private var followersListView: some View {
        ForEach(followers, id: \.uid) { user in
            NavigationLink(destination: ProfileView(viewModel: ProfileViewModel(user: user), router: router)) {
                UserCell(user: user)
            }
        }
    }

    private func fetchFollowers(showLoading: Bool) async {
        if showLoading {
            isLoading = true
        }
        errorMessage = nil

        print("DEBUG: Fetching followers for userID: \(userID)")

        let result = await followService.getFollowers(for: userID)

        switch result {
        case .success(let users):
            print("DEBUG: Successfully fetched followers: \(users.map { $0.name })")
            followers = users
        case .failure(let error):
            print("ERROR: Failed to fetch followers: \(error.localizedDescription)")
            errorMessage = "データの取得に失敗しました"
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        FollowersListView(userID: "AhGAfsGPU8cwvsONT2duSFcQGdJ2", router: nil)
            .navigationBarTitleDisplayMode(.inline)
    }
}
