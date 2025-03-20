//
//  EditExerciseSetView.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2025/03/19
//  
//

import SwiftUI

struct EditExerciseSetView: View {
    
    @Environment(\.dismiss) var dismiss
    let order: Int
    @Binding var workoutExercise: WorkoutExercise
    
    private let exerciseDetailOptions = ["セット", "レップ数", "重さ"]
    
    var body: some View {
        VStack {
            
            headerBox
            
            Divider()
            
            setsBox
        }
        .padding()
        .padding(.top)
        .background(Color.gray.opacity(0.1))
    }
}

// MARK: views
extension EditExerciseSetView {
    private var headerBox: some View {
        HStack(spacing: 16) {
            Text("\(order)")
                .font(.title2)
                .fontWeight(.semibold)
                .padding()
                .background(.main)
                .clipShape(Circle())
            
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
            
            Button(action: {
                dismiss()
            }, label: {
                Image(systemName: "xmark")
                    .font(.title).bold()
            })
            .tint(.primary)
        }
    }
    
    private var setsBox: some View {
        VStack {
            HStack {
                ForEach(exerciseDetailOptions, id: \.self) { name in
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .hAlign(.center)
                }
            }
            
            ScrollView(showsIndicators: false) {
                ForEach($workoutExercise.sets, id: \.id) { $set in
                    HStack {
                        Text("\(workoutExercise.sets.firstIndex(where: { $0.id == set.id })! + 1)")
                            .hAlign(.center)
                            .font(.headline)

                        TextField("", value: $set.reps, format: .number)
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .fieldBackground()
                            .clipped()
                            .shadow(radius: 1)
                            .padding(4)

                        TextField("", value: $set.weight, format: .number)
                            .multilineTextAlignment(.center)
                            .keyboardType(.decimalPad)
                            .fieldBackground()
                            .clipped()
                            .shadow(radius: 1)
                            .padding(4)
                    }
                    .overlay(alignment: .leading) {
                        if workoutExercise.sets.count > 1, workoutExercise.sets.last?.id == set.id {
                            Button(action: {
                                workoutExercise.sets.removeAll { $0.id == set.id }
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundStyle(.white)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(8)
                                    .background(.red)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                
                Button {
                    if let lastSet = workoutExercise.sets.last {
                        workoutExercise.sets.append(ExerciseSet(reps: lastSet.reps, weight: lastSet.weight))
                    } else {
                        workoutExercise.sets.append(ExerciseSet(reps: 0, weight: 0))
                    }
                } label: {
                    Label("セットを追加する", systemImage: "plus")
                        .font(.headline)
                }
                .buttonStyle(CapsuleButtonStyle(color: .main))
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    EditExerciseSetView(order: 1, workoutExercise: .constant(.mock()))
}
