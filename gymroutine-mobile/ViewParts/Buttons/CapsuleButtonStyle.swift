//
//  CapsuleButtonStyle.swift
//  gymroutine-mobile
//
//  Created by 森祐樹 on 2025/03/03.
//

import Foundation
import SwiftUI

/**
 ### 背景色
 - 指定可能
 ### 形
 - カプセル
 ### 用途
 - プロフィールのアクションボタン（フォローする/フォロー中/プロフィール編集）
 */
struct CapsuleButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) var isEnabled: Bool
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.vertical, 10)
            .hAlign(.center)
            .background(color, in: Capsule())
            .opacity(configuration.isPressed || !self.isEnabled ? 0.5 : 1.0)
    }
}
