//
//  FollowersListView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/03/01.
//

import SwiftUI

struct FollowersListView: View {
    let userID: String
    @State private var followers: [User] = []
    @State private var errorMessage: String? = nil
    private let followService = FollowService()
    
    var body: some View {
        List {
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            } else {
                ForEach(followers, id: \.uid) { user in
                    HStack {
                        if let url = URL(string: user.profilePhoto), !user.profilePhoto.isEmpty {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 50, height: 50)
                            }
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                        }
                        Text(user.name)
                    }
                }
            }
        }
        .navigationTitle("フォロワー")
        .task {
            let result = await followService.getFollowers(for: userID)
            switch result {
            case .success(let users):
                followers = users
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}
