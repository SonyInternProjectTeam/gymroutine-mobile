//
//  NewExeciseDetailView.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2025/03/17
//  
//

import SwiftUI

struct NewExerciseDetailView: View {
    
    let exercise: Exercise
    let isReadOnly: Bool
    let onAddButtonTapped: (() -> Void)?
    
    
    init(exercise: Exercise, isReadOnly: Bool, onAddButtonTapped: (() -> Void)? = nil) {
        self.exercise = exercise
        self.isReadOnly = isReadOnly
        self.onAddButtonTapped = onAddButtonTapped
    }
    
    var body: some View {
        ScrollView {
            headerBox
            
            VStack(spacing: 24) {
                exercisePartBox
                
                exerciseDescriptionBox
            }
            .padding()
        }
        .overlay(alignment: .bottom) {
            if !isReadOnly {
                buttonBox
                    .padding()
            }
        }
        .background(Color.gray.opacity(0.1))
        .contentMargins(.top, 16)
        .contentMargins(.bottom, 80)
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension NewExerciseDetailView {
    private var headerBox: some View {
        Image(.welcomeLogo)
            .resizable()
            .scaledToFit()
            .frame(height: 400)
    }
    
    private var exercisePartBox: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("部位")
                .font(.headline)
            
            Text(exercise.part)
                .padding(.vertical, 8)
                .padding(.horizontal)
                .background()
                .clipShape(Capsule())
        }
        .hAlign(.leading)
    }
    
    private var exerciseDescriptionBox: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("説明")
                .font(.headline)
            
            Text(exercise.description)
        }
        .hAlign(.leading)
    }
    
    private var buttonBox: some View {
        Button(action: {
            onAddButtonTapped?()
        }, label: {
            Label("追加する", systemImage: "plus")
                .font(.headline)
        })
        .buttonStyle(CapsuleButtonStyle(color: .main))
    }
}

#Preview {
    NavigationStack {
        NewExerciseDetailView(
            exercise: .mock(),
            isReadOnly: false,
            onAddButtonTapped: {
                print("追加処理")
            }
        )
    }
}
