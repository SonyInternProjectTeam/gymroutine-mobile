//
//  UserCell.swift
//  gymroutine-mobile
//
//  Created by 森祐樹 on 2025/04/27.
//

import SwiftUI

/// ユーザ情報を表示するCell（汎用・横長）
/// 用途：フォロワー・フォロー中・ユーザー検索のユーザー一覧画面
struct UserCell: View {

    let user: User

    var body: some View {
        HStack(spacing: 12) {
            ProfileIcon(profileUrl: user.profilePhoto, size: .medium2)

            Text(user.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
        }
        .hAlign(.leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(1..<11) { i in
                    NavigationLink(destination: {Text("a")}) {
                        UserCell(user: User(uid: "previewUser1", email: "preview@example.com", name: "Preview User"))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.mainBackground)
    }
}
