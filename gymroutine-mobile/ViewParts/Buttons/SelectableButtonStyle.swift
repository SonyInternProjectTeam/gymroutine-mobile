//
//  SelectableButtonStyle.swift
//  gymroutine-mobile
//
//  Created by 森祐樹 on 2024/12/30.
//

import SwiftUI

/**
 ### 背景色
 - 選択時：`main` / 未選択時：`secondary`
 ### 形
 - 横長長方形・角丸
 ### 用途
 - 性別選択
 */
struct SelectableButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .bold()
            .foregroundStyle(isSelected ? .main : .secondary)
            .hAlign(.center)
            .padding(.vertical, 20)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.main.opacity(0.1) : .clear)
                    .strokeBorder(isSelected ? .main : .secondary, lineWidth: 1)
            }
            .contentShape(Rectangle())
    }
}
