//
//  ButtonView.swift
//  gymroutine-mobile
//
//  Created by 森祐樹 on 2024/11/22.
//

import SwiftUI

/**
 ### 背景色
 - `mainColor`
 ### 形
 - 横長長方形・角丸
 ### 用途
 - 新規登録の選択ボタン
 */
struct PrimaryButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: 315, maxHeight: 48)
            .background(Color.main.cornerRadius(10))
            .opacity(configuration.isPressed ? 0.5 : 1.0)
    }
}
