//
//  ExersiceCategoryToggle.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2024/11/26.
//

import SwiftUI

struct ExercisePartToggle: View {

    var flag = false
    let exercisePart: ExercisePart

    var body: some View {
        Text (exercisePart.rawValue)
            .padding(.vertical, 8)
            .hAlign(.center)
            .foregroundStyle(Color.black)
            .background (
                Capsule()
                    .fill(flag ? Color.blue.opacity(0.1): Color.white)
                    .strokeBorder(flag ? Color.blue: Color.gray, lineWidth: flag ? 3: 1)
            )
    }
}

#Preview {
    HStack {
        ExercisePartToggle(exercisePart: .arm)
        ExercisePartToggle(flag: true, exercisePart: .arm)
        ExercisePartToggle(flag: true, exercisePart: .arm)
    }
}
