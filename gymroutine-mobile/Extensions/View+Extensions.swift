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
