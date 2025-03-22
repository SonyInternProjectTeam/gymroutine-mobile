//
//  UserCell.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2025/02/25.
//

import SwiftUI

struct UserProfileView: View {
    
    var user: User 
    
    var body: some View {
        VStack {
            HStack {
                ProfilePhoto(photourl: user.profilePhoto)
                VStack {
                    Text("\(user.age)歳 \(user.gender)")
                        .font(.caption)
                        .fontWeight(.thin)
                    Text(user.name)
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                .frame(width: 56, height: 56)
            }
            followButton()
                .frame(width: 130, height: 28)
        }
        .frame(width: 156,height: 116)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}


struct UserListView:View {
    
    var user: User
    
    var body: some View {
        HStack {
            ProfilePhoto(photourl: user.profilePhoto)
            VStack {
                Text(user.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text("\(user.age)歳 \(user.gender)")
                    .font(.caption)
                    .fontWeight(.thin)
            }
            Spacer()
        }
        .background(Color.white)
    }
}


@ViewBuilder
private func followButton() -> some View {
    Button(action: {
        // フォロー処理
    }) {
        Text("フォロー")
            .foregroundColor(.black)
            .font(.caption)
            .fontWeight(.semibold)
    }
    .buttonStyle(PrimaryButtonStyle())
}

@ViewBuilder
private func ProfilePhoto(photourl: String) -> some View {
    Group {
        if !photourl.isEmpty {
            AsyncImage(url: URL(string: photourl)) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                ProgressView()
            }
        } else {
            Image(systemName: "person.circle")
                .resizable()
                .foregroundColor(.gray)
        }
    }
    .frame(width: 56, height: 56)
    .clipShape(Circle())
    
}
