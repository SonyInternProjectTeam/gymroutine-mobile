//
//  EditSetView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/05/21.
//

import SwiftUI

struct EditSetView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var weight: Double
    @State private var reps: Int
    private let analyticsService = AnalyticsService.shared
    
    var onSave: (Double, Int) -> Void
    
    init(weight: Double, reps: Int, onSave: @escaping (Double, Int) -> Void) {
        self._weight = State(initialValue: weight)
        self._reps = State(initialValue: reps)
        self.onSave = onSave
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("セット編集")
                .font(.headline)
                .padding(.top)
            
            VStack(spacing: 20) {
                // 무게 편집
                VStack(alignment: .leading, spacing: 8) {
                    Text("重さ (kg)")
                        .font(.subheadline)
                    
                    HStack {
                        Button(action: { 
                            if weight >= 2.5 {
                                weight -= 2.5
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        
                        Slider(value: $weight, in: 0...300, step: 2.5)
                            .tint(.blue)
                        
                        Button(action: {
                            weight += 2.5
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text("\(String(format: "%.1f", weight)) kg")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .font(.title2)
                        .bold()
                }
                
                // 렙수 편집
                VStack(alignment: .leading, spacing: 8) {
                    Text("レップ数")
                        .font(.subheadline)
                    
                    HStack {
                        Button(action: { 
                            if reps > 1 {
                                reps -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(reps) },
                            set: { reps = Int($0) }
                        ), in: 1...50, step: 1)
                            .tint(.blue)
                        
                        Button(action: {
                            reps += 1
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text("\(reps) 回")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .font(.title2)
                        .bold()
                }
            }
            .padding(.horizontal)
            
            HStack {
                Button("キャンセル") {
                    dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("保存") {
                    onSave(weight, reps)
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.top)
        }
        .padding()
        .onAppear {
            // Log screen view
            analyticsService.logScreenView(screenName: "EditSet")
        }
    }
}

#Preview {
    EditSetView(weight: 50.0, reps: 10) { _, _ in }
} 