//
//  UserSearchField.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2025/02/25.
//

import SwiftUI

struct UserSearchField: View {
    
    @Binding var text: String
    
    var onSubmit: () -> Void = { }
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("ユーザーを検索", text: $text)
                .onSubmit {
                    onSubmit()
                }
        }
        .padding(.horizontal,16)
        .frame(height: 40)
        .background(
            Capsule()
                .fill(Color(UIColor.systemGray6))
        )
    }
}

#Preview {
    @Previewable @State var text: String = ""
    UserSearchField(text: $text)
}
