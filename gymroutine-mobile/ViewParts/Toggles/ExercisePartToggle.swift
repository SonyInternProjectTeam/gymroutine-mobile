//
//  ExersiceCategoryToggle.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2024/11/26.
//

import SwiftUI

struct ExercisePartToggle: View {

    let exercisePart: ExercisePart?

    var body: some View {
        if  exercisePart != nil {
            Text (exercisePart!.rawValue)
                .padding(.vertical, 8)
                .hAlign(.center)
                .foregroundStyle(Color.black)
                .background (
                    Capsule()
                        .fill(Color.white)
                        .strokeBorder(Color.gray)
                )
        } else {
            Text ("ALL")
                .padding(.vertical, 8)
                .hAlign(.center)
                .foregroundStyle(Color.black)
                .background (
                    Capsule()
                        .fill(Color.white)
                        .strokeBorder(Color.gray)
                )
        }
        
    }
}

#Preview {
    HStack {
        ExercisePartToggle(exercisePart: .arm)
//        ExercisePartToggle(flag: true, exercisePart: .arm)
//        ExercisePartToggle(flag: true, exercisePart: .arm)
    }
}
