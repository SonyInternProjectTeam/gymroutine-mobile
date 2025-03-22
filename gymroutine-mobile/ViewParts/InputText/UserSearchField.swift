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
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("ユーザーを検索", text: $text)
                .onChange(of: text) {
                }
        }
        .fieldBackground()
    }
}
