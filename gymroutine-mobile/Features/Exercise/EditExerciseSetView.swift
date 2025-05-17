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
    private let analyticsService = AnalyticsService.shared
    
    // 문자열로 변환된 값을 저장하기 위한 상태 변수
    @State private var repsStrings: [String] = []
    @State private var weightStrings: [String] = []
    
    private let exerciseDetailOptions = ["セット", "レップ数", "重さ"]
    
    // 초기화 시 렙수와 무게 값을 문자열로 변환
    init(order: Int, workoutExercise: Binding<WorkoutExercise>) {
        self.order = order
        self._workoutExercise = workoutExercise
        
        // 초기 문자열 값 설정
        let reps = workoutExercise.wrappedValue.sets.map { "\($0.reps)" }
        let weights = workoutExercise.wrappedValue.sets.map { String(format: "%.1f", $0.weight) }
        self._repsStrings = State(initialValue: reps)
        self._weightStrings = State(initialValue: weights)
    }
    
    var body: some View {
        VStack {
            
            headerBox
            
            Divider()
            
            setsBox
        }
        .padding()
        .padding(.top)
        .background(Color.gray.opacity(0.1))
        .onAppear {
            // Log screen view
            analyticsService.logScreenView(screenName: "EditExerciseSet")
        }
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

            ExerciseImageCell(imageName: workoutExercise.key)
                .frame(width: 56, height: 56)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(workoutExercise.toPartName())
                    .font(.caption)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.secondary.opacity(0.4), lineWidth: 2)
                    )
                
                Text(LocalizedStringKey(workoutExercise.name))
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
                ForEach(Array(workoutExercise.sets.enumerated()), id: \.element.id) { index, set in
                    HStack {
                        Text("\(index + 1)")
                            .hAlign(.center)
                            .font(.headline)

                        // 렙수 입력 필드 (문자열 기반)
                        TextField("0", text: Binding(
                            get: {
                                if index < repsStrings.count {
                                    return repsStrings[index]
                                }
                                return "0"
                            },
                            set: { newValue in
                                // 문자열 배열 업데이트
                                if index < repsStrings.count {
                                    repsStrings[index] = newValue
                                } else if index == repsStrings.count {
                                    repsStrings.append(newValue)
                                }
                                
                                // 실제 모델 업데이트
                                if let intValue = Int(newValue) {
                                    workoutExercise.sets[index].reps = intValue
                                } else if newValue.isEmpty {
                                    // 비어있으면 0으로 설정
                                    workoutExercise.sets[index].reps = 0
                                }
                            }
                        ))
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .fieldBackground()
                        .clipped()
                        .shadow(radius: 1)
                        .padding(4)

                        // 무게 입력 필드 (문자열 기반)
                        TextField("0.0", text: Binding(
                            get: {
                                if index < weightStrings.count {
                                    return weightStrings[index]
                                }
                                return "0.0"
                            },
                            set: { newValue in
                                // 문자열 배열 업데이트
                                if index < weightStrings.count {
                                    weightStrings[index] = newValue
                                } else if index == weightStrings.count {
                                    weightStrings.append(newValue)
                                }
                                
                                // 실제 모델 업데이트
                                if let doubleValue = Double(newValue.replacingOccurrences(of: ",", with: ".")) {
                                    workoutExercise.sets[index].weight = doubleValue
                                } else if newValue.isEmpty {
                                    // 비어있으면 0으로 설정
                                    workoutExercise.sets[index].weight = 0
                                }
                            }
                        ))
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
                                // 배열도 함께 조정
                                if repsStrings.count > workoutExercise.sets.count {
                                    repsStrings.removeLast()
                                }
                                if weightStrings.count > workoutExercise.sets.count {
                                    weightStrings.removeLast()
                                }
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
                        // 배열도 함께 업데이트
                        repsStrings.append("\(lastSet.reps)")
                        weightStrings.append(String(format: "%.1f", lastSet.weight))
                    } else {
                        workoutExercise.sets.append(ExerciseSet(reps: 0, weight: 0))
                        // 배열도 함께 업데이트
                        repsStrings.append("0")
                        weightStrings.append("0.0")
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
