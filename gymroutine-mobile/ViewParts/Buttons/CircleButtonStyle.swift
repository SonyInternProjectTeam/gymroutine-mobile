//
//  CircleButtonStyle.swift
//  gymroutine-mobile
//
//  Created by 森祐樹 on 2024/11/25.
//

import SwiftUI

/**
 ### 背景色
 - `mainColor`
 ### 形
 - 円形
 ### 用途
 - ログイン・新規登録の実行ボタン
 */
struct CircleButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title)
            .foregroundStyle(.white)
            .padding(20)
            .background(.main, in: Circle())
            .opacity(configuration.isPressed ? 0.5 : 1.0)
    }
}
