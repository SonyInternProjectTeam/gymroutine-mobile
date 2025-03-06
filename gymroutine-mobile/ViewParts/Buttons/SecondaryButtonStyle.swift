//
//  SecondaryButtonStyle.swift
//  gymroutine-mobile
//
//  Created by 森祐樹 on 2024/11/25.
//

import SwiftUI

/**
 ### 背景色
 - `systemGray5`
 ### 形
 - 横長長方形・角丸
 ### 用途
 - ログインの選択ボタン
 */
struct SecondaryButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.main)
            .frame(maxWidth: 315, maxHeight: 48)
            .background(Color(UIColor.systemGray5).cornerRadius(10))
            .opacity(configuration.isPressed ? 0.5 : 1.0)
    }
}
