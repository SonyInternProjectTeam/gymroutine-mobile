//
//  RestTimeSettingsView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/05/21.
//

import SwiftUI

struct RestTimeSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var workoutExercise: WorkoutExercise
    var onSave: () -> Void
    
    @State private var selectedTime: Int
    
    private let restTimeOptions = [30, 45, 60, 90, 120, 180]
    
    init(workoutExercise: Binding<WorkoutExercise>, onSave: @escaping () -> Void) {
        self._workoutExercise = workoutExercise
        self.onSave = onSave
        self._selectedTime = State(initialValue: workoutExercise.wrappedValue.restTime ?? 90)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "timer")
                Text("休憩設定")
            }
            .font(.headline)
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider()

            VStack(spacing: 8) {
                Text(LocalizedStringKey(workoutExercise.name))
                    .foregroundStyle(.secondary)
                    .font(.title3)
                    .fontWeight(.bold)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(selectedTime)")
                        .font(Font(UIFont.monospacedDigitSystemFont(ofSize: 48, weight: .bold)))
                    Text("秒")
                        .font(.title3)
                        .bold()
                }
                .foregroundColor(.blue)
            }
            .vAlign(.center)
            
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Button(action: {
                        if selectedTime > 15 {
                            selectedTime -= 15
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    
                    Slider(value: Binding(
                        get: { Double(selectedTime) },
                        set: { selectedTime = Int($0) }
                    ), in: 15...300, step: 5)
                    .tint(.blue)
                    
                    Button(action: {
                        if selectedTime < 300 {
                            selectedTime += 15
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 24)

                HStack(spacing: 16) {
                    ForEach(restTimeOptions, id: \.self) { time in
                        Button(action: {
                            selectedTime = time
                        }) {
                            Text("\(time)")
                                .font(.footnote)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedTime == time ? Color.blue : Color.blue.opacity(0.1))
                                .foregroundColor(selectedTime == time ? .white : .blue)
                                .cornerRadius(20)
                        }
                    }
                }
            }
            
            HStack {
                Button("キャンセル") {
                    dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("保存") {
                    workoutExercise.restTime = selectedTime
                    print("휴식 시간 설정: \(selectedTime)초")
                    onSave()
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.top, 32)
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    Text("a")
        .sheet(isPresented: .constant(true)) {
            RestTimeSettingsView(
                workoutExercise: .constant(WorkoutExercise.mock()),
                onSave: { }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    
}
