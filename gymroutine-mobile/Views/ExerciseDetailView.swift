//
//  ExerciseDetailView.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2024/11/26.
//

import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise
    var body: some View {
        VStack(alignment: .center, spacing: 0){
            Divider()
            Image(.welcomeLogo)
                .resizable()
                .scaledToFit()
                .frame(height:400)
            VStack(spacing: 20) {
                PositionView
                ExplanationView
                Spacer()
                
                NavigationLink(destination:SignupView()) {
                    Text("追加する")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.bottom, 16)
            .padding([.top, .horizontal], 24)
            .background(Color(.systemGray6))
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        
    }
    
    private var PositionView: some View {
        VStack(alignment: .leading) {
            Text("部位")
                .font(.title3)
                .fontWeight(.bold)
            HStack (spacing: 0){
                if let exercisepart = exercise.toExercisePart() {
                    ExercisePartToggle(exercisePart: exercisepart)
                        .disabled(true)
                }
            }
        }
        .hAlign(.leading)
    }
    
    private var ExplanationView: some View {
        VStack(alignment: .leading, spacing:20){
            Text("説明")
                .font(.title3)
                .fontWeight(.bold)
            Text(exercise.description)
                .font(.footnote)
                .fontWeight(.regular)
        }
        .hAlign(.leading)
    }
    
}
