//
//  ExerciseDetailView.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2024/11/26.
//

import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise
    let workoutID: String // Workout ID를 전달받음
    @StateObject private var viewModel = ExerciseDetailViewModel()
    @State private var navigateToWorkoutDetail = false // 화면 전환 플래그
    
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
        .background(
            NavigationLink(
                destination: WorkoutDetailView(workoutID: workoutID),
                isActive: $navigateToWorkoutDetail
            ) {
                EmptyView()
            }
        ) // 운동 추가 후 자동 전환
    }
}

// MARK: - BottomView
extension ExerciseDetailView {
    private var BottomView: some View {
        VStack(alignment: .center, spacing: 16) {
            PositionView
            
            ExplanationView
            
            Spacer()
            
            Button(action: {
                // WorkoutExercise 객체 생성 (초기 세트 배열은 빈 배열)
                let newExercise = WorkoutExercise(
                    id: UUID().uuidString,
                    name: exercise.name,
                    part: exercise.part,
                    sets: []  // 초기에는 빈 배열
                )
                viewModel.addExerciseToWorkout(workoutID: workoutID, exercise: newExercise) { success in
                    if success {
                        print("운동 추가 성공 ✅")
                        navigateToWorkoutDetail = true // WorkoutDetailView로 이동
                    } else {
                        print("운동 추가 실패 ❌")
                    }
                }
            }) {
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

