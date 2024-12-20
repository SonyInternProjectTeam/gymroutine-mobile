//
//  ExerciseSearchField.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2024/12/16.
//

import SwiftUI

struct ExerciseSearchField: View {
    
    @Binding var text: String
    var onSubmit: () -> Void = { }
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("エクササイズを検索", text: $text)
        }
        .fieldBackground()
        .onSubmit {
            onSubmit()
        }
    }
}

#Preview {
    @Previewable @State var text = ""
    ExerciseSearchField(text: $text)
}
