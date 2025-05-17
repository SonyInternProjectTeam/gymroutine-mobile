//
//  ExerciseGridCell.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2025/03/17
//  
//

import SwiftUI

struct ExerciseGridCell: View {
    
    let exercise: Exercise
    let isReadOnly: Bool
    var onTapPlusButton: (() -> Void)?

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            if let image = UIImage(named: exercise.key) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .background(.secondary.opacity(0.2))
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(exercise.toPartName())
                        .font(.footnote)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)

                    Spacer()
                    
                    if !isReadOnly {
                        Button {
                            onTapPlusButton?()
                        } label: {
                            Image(systemName: "plus")
                                .font(.headline)
                                .foregroundStyle(.main)
                        }
                    }
                }

                Text(LocalizedStringKey(exercise.name))
                    .font(.callout)
                    .fontWeight(.regular)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
        }
        .tint(.primary)
        .background()
        .cornerRadius(8)
        .clipped()
        .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1.5)
    }
}

#Preview {
    ExerciseGridCell(exercise: .mock(), isReadOnly: true)
}
