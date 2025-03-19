//
//  WorkoutExerciseCell.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2025/03/17
//  
//

import SwiftUI

struct WorkoutExerciseCell: View {
    
    let workoutExercise: WorkoutExercise
    private let exerciseDetailOptions = ["セット", "レップ数", "重さ"]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.main)
                    .frame(width: 56, height: 56)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(workoutExercise.part)
                        .font(.caption)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.secondary.opacity(0.4), lineWidth: 2)
                        )
                    
                    Text(workoutExercise.name)
                        .font(.headline)
                }
                .hAlign(.leading)
            }
            
            Divider()
            
            VStack(spacing: 16) {
                
                HStack {
                    ForEach(exerciseDetailOptions, id: \.self) { name in
                        Text(name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .hAlign(.center)
                    }
                }
                
                ForEach(Array(workoutExercise.sets.enumerated()), id: \.element.id) { index, set in
                    HStack {
                        Text("\(index + 1)").hAlign(.center)
                        
                        Text("\(set.reps)").hAlign(.center)
                        
                        Text(String(format: "%.1f", set.weight)).hAlign(.center)
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .clipShape(.rect(cornerRadius: 8))
        .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1.5)
    }
}

#Preview {
    VStack {
        WorkoutExerciseCell(workoutExercise: .mock())
            .padding()
    }
    .vAlign(.center)
    .background(Color.gray.opacity(0.1))
}
