//
//  ButtonView.swift
//  gymroutine-mobile
//
//  Created by 森祐樹 on 2024/11/22.
//

import SwiftUI

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
