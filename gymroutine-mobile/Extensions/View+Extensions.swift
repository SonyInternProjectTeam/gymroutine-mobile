//
//  View+Extensions.swift
//  gymroutine-mobile
//
//  Created by 森祐樹 on 2024/11/22.
//

import SwiftUI

extension View {
    func hAlign(_ alignment: Alignment) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: alignment)
    }

    func vAlign(_ alignment: Alignment) -> some View {
        self
            .frame(maxHeight: .infinity, alignment: alignment)
    }
}

// MARK: - modifier

extension View {
    func fieldBackground() -> some View {
        self
            .padding(.horizontal,12)
            .frame(height: 48)
            .background(
                Color(UIColor.systemGray6)
                    .cornerRadius(10)
            )
    }
}
