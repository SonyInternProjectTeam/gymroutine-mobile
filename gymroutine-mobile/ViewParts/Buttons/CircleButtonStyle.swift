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
 - 新規登録後のプロフィール登録のネクストボタン
 */
struct CircleButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) var isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title)
            .foregroundStyle(.white)
            .padding(20)
            .background(.main, in: Circle())
            .opacity(configuration.isPressed || !self.isEnabled ? 0.5 : 1.0)
    }
}
