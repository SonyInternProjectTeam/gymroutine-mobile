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
        VStack(alignment: .center, spacing: 0) {
            Divider()

            Image(.welcomeLogo)
                .resizable()
                .scaledToFit()
                .frame(height: 400)

            BottomView
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - BottomView
extension ExerciseDetailView {
    private var BottomView: some View {
        VStack(alignment: .center, spacing: 16) {
            PositionView

            ExplanationView

            Spacer()

            Button(action: {}) {
                Text("追加する")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.bottom, 16)
        .padding([.top, .horizontal], 24)
        .background(Color(.systemGray6))
    }

    private var PositionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("部位")
                .font(.title3)
                .fontWeight(.bold)
            if let exercisepart = exercise.toExercisePart() {
                ExercisePartToggle(exercisePart: exercisepart)
                    .disabled(true)
            }
        }
        .hAlign(.leading)
    }

    private var ExplanationView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("説明")
                .font(.title3)
                .fontWeight(.bold)
            Text(exercise.description)
                .font(.footnote)
        }
        .hAlign(.leading)
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: Exercise(name: "ショルダープレス", description: "あああ", img: "", part: "arm"))
    }
}
