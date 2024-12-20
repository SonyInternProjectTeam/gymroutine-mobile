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
//        Button{
////            flag.toggle()
//        } label: {
            Text (exercisePart.rawValue)
                .frame(width: 100, height: 35)
                .foregroundStyle(Color.black)
                .background(flag ? Color.blue.opacity(0.1): Color.white)
                .cornerRadius(30)
                .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(flag ? Color.blue: Color.gray, lineWidth: flag ? 3: 1)
                )
//        }
        .fixedSize()
        }
        
}

#Preview {
    ExercisePartToggle(exercisePart: .arm)
}
