//
//  CircleButtonStyle.swift
//  gymroutine-mobile
//
//  Created by 森祐樹 on 2024/11/25.
//

import SwiftUI

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
