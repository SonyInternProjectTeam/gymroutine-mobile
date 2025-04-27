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
        HStack {
            ProfileIcon(profileUrl: user.profilePhoto, size: .medium)
            Text(user.name)
        }
    }
}

#Preview {
    UserCell(user: User(uid: "previewUser1", email: "preview@example.com", name: "Preview User"))
}
