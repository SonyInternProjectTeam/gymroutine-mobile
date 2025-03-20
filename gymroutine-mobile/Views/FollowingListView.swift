//
//  FollowingListView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/03/01.
//

import SwiftUI

struct FollowingListView: View {
    let userID: String
    @State private var following: [User] = []
    @State private var errorMessage: String? = nil
    private let followService = FollowService()
    
    var body: some View {
        List {
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            } else {
                ForEach(following, id: \.uid) { user in
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
        .navigationTitle("フォロー中")
        .task {
            UIApplication.showLoading()
            print("DEBUG: Loading following list for userID: \(userID)")
            let result = await followService.getFollowing(for: userID)
            switch result {
            case .success(let users):
                print("DEBUG: Successfully fetched following users: \(users.map { $0.name })")
                following = users
            case .failure(let error):
                print("ERROR: Failed to fetch following users: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
            UIApplication.hideLoading()
        }
    }
}
