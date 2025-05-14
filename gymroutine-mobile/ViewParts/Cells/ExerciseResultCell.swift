//
//  ExerciseResultCell.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2025/04/27
//  
//

import SwiftUI

struct ExerciseResultCell: View {
    
    let exerciseIndex: Int?
    let exercise: ExerciseResultModel
    private let exerciseDetailOptions = ["セット", "レップ数", "重さ"]
    
    init(exerciseIndex: Int? = nil, exercise: ExerciseResultModel) {
        self.exerciseIndex = exerciseIndex
        self.exercise = exercise
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack() {
                if let exerciseIndex {
                    Text("\(exerciseIndex)")
                        .font(.title2.bold())
                }
                
                Text(exercise.exerciseName)
                    .font(.headline)
            }
            .foregroundStyle(.white)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ForEach(exerciseDetailOptions, id: \.self) { optionName in
                        Text(optionName)
                            .foregroundStyle(.white)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .hAlign(.center)
                    }
                }

                ForEach(exercise.sets.indices, id: \.self) { index in
                    let set = exercise.sets[index]
                    HStack {
                        Text("\(index + 1)")
                            .hAlign(.center)
                        
                        Text("\(set.Reps)")
                            .hAlign(.center)
                        
                        if let weight = set.Weight {
                            Text("\(weight, specifier: "%.1f") kg")
                                .hAlign(.center)
                        } else {
                            Spacer()
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                }
            }
        }
        .padding()
        .background(.main.gradient)
        .clipShape(.rect(cornerRadius: 8))
    }
}

#Preview {
    VStack {
        ExerciseResultCell(exerciseIndex: 3, exercise: .mock)
        
        ExerciseResultCell(exercise: .mock)
    }
    .padding()
}
