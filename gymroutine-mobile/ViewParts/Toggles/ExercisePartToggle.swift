//
//  ExersiceCategoryToggle.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2024/11/26.
//

import SwiftUI

struct ExercisePartToggle: View {

    let partName: String

    init(exercisePart: ExercisePart?) {
        if let exercisePart = exercisePart {
            partName = exercisePart.rawValue
        } else {
            partName = "ALL"
        }
    }

    var body: some View {
        Text(LocalizedStringKey(partName))
            .padding(.vertical, 8)
            .foregroundStyle(Color.black)
            .hAlign(.center)
            .background (
                Capsule()
                    .fill(Color.white)
                    .strokeBorder(Color.gray)
            )
    }
}

#Preview {
    ExercisePartToggle(exercisePart: .arm)
}
