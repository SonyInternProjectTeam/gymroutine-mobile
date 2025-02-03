//
//  ExersiceSelectButton.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2024/11/29.
//

import SwiftUI

struct ExersiceSelectButton: View {

    let exercise: Exercise

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Image(.workout)
                .resizable()
                .scaledToFit()
                .padding(16)
                .background(.secondary.opacity(0.2))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(exercise.part)
                        .font(.footnote)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)

                    Spacer()

                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundStyle(.main)
                }

                Text(exercise.name)
                    .font(.callout)
                    .fontWeight(.regular)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
        }
        .tint(.primary)
        .background(.white)
        .cornerRadius(8)
        .clipped()
        .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1.5)
    }
}

