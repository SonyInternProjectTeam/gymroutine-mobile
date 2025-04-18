//
//  WorkoutCell.swift
//  gymroutine-mobile
//
//  Created by SATTSAT on 2025/01/09
//
//

import SwiftUI

struct WorkoutCell: View {
    let workoutName: String
    let exerciseImageName: String?
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            ExerciseImageCell(imageName: exerciseImageName)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 8) {
                Text("\(count) 種目")
                    .font(.system(size: 10))
                    .tint(.secondary)

                Text(workoutName)
                    .font(.system(size: 16, weight: .bold))
                    .tint(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .resizable()
                .tint(.secondary)
                .frame(width: 6, height: 12)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .compositingGroup()
        .shadow(color: .black.opacity(0.08), radius: 4)
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(1..<11) { i in
                    NavigationLink(destination: {Text("a")}) {
                        WorkoutCell(workoutName: "一軍ワークアウト",
                                    exerciseImageName: "Squat",
                                    count: i)
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.mainBackground)
    }
}

