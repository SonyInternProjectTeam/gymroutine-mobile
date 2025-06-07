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
    private let analyticsService = AnalyticsService.shared
    
    
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
        .onAppear {
            // Log screen view
            analyticsService.logScreenView(screenName: "ExerciseDetail")
        }
    }
}

extension ExerciseDetailView {
    private var headerBox: some View {
        Group {
            if let image = UIImage(named: exercise.key) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 400)
                    .background(.white)
            } else {
                Label("画像を表示できません", systemImage: "photo.badge.exclamationmark.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(height: 400)
                    .frame(maxWidth: .infinity)
                    .background(.white)
            }
        }
    }

    
    private var exercisePartBox: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("部位")
                .font(.headline)
            
            HStack{
                Text(exercise.toPartName())
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background()
                    .clipShape(Capsule())

                Text(exercise.toDetailedPartName())
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
