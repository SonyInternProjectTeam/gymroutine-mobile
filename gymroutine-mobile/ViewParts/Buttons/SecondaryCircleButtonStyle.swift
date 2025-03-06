//
//  SecondaryCircleButtonStyle.swift
//  gymroutine-mobile
//
//  Created by 森祐樹 on 2025/01/13.
//

import SwiftUI

/**
 ### 背景色
 -`systemGray5`
 ### 形
 - 円形
 ### 用途
 - 新規登録後のプロフィール登録のバックボタン
 */
struct SecondaryCircleButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) var isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title)
            .foregroundStyle(.main)
            .padding(20)
            .background(Color(UIColor.systemGray5), in: Circle())
            .opacity(configuration.isPressed || !self.isEnabled ? 0.5 : 1.0)
    }
}
