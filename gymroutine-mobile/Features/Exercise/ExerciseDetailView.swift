//
//  NewExerciseDetailView.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2025/03/17
//  
//

import SwiftUI

struct ExerciseDetailView: View {
    
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
        .navigationTitle(LocalizedStringKey(exercise.name))
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension ExerciseDetailView {
    private var headerBox: some View {
        if let image = UIImage(named: exercise.key) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 400)
                        .background(.white)
        } else {
                    Image(.welcomeLogo)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 400)
                        .background(.white)
        }
    }

    
    private var exercisePartBox: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("部位")
                .font(.headline)
            
            HStack{
                Text(LocalizedStringKey(exercise.part))
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background()
                    .clipShape(Capsule())
                
                Text(LocalizedStringKey(exercise.detailedPart))
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background()
                    .clipShape(Capsule())
            }
            
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
        ExerciseDetailView(
            exercise: .mock(),
            isReadOnly: false,
            onAddButtonTapped: {
                print("追加処理")
            }
        )
    }
}
