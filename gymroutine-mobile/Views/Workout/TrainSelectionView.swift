//
//  TrainSelectionView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/11/08.
//

import SwiftUI

struct TrainSelectionView: View {
    let workoutID: String  // workoutID를 전달받도록 추가
    @ObservedObject var viewModel = CreateWorkoutViewModel()
    @State private var selectedTrain: String? = nil
    @State private var selectedExercise: String? = nil
    
    var body: some View {
        VStack {
            Text("Choose a Workout")
                .font(.title)
                .padding()
            
            // 트레인 옵션 리스트
            List(viewModel.trainOptions, id: \.self) { option in
                Button(action: {
                    selectedTrain = option
                    viewModel.fetchExercises(for: option)
                }) {
                    Text(option)
                }
            }
            
            // 선택된 트레인에 따른 운동 리스트
            if let selectedTrain = selectedTrain {
                Text("Exercises for \(selectedTrain)")
                    .font(.headline)
                    .padding()
                
                List(viewModel.exercises, id: \.self) { exercise in
                    Button(action: {
                        selectedExercise = exercise
                        // WorkoutExercise 객체 생성 (초기 세트 배열은 빈 배열)
                        let newExercise = WorkoutExercise(
                            id: UUID().uuidString,
                            name: exercise,
                            part: selectedTrain,
                            sets: []
                        )
                        viewModel.addExerciseToWorkout(workoutID: workoutID, exercise: newExercise) { success in
                            if success {
                                print("운동 추가 성공 ✅")
                            } else {
                                print("운동 추가 실패 ❌")
                            }
                        }
                    }) {
                        Text(exercise)
                    }
                }
            }
            
            Spacer()
        }
        .onAppear {
            viewModel.fetchTrainOptions()
        }
        .navigationTitle("Train Selection")
    }
}

#Preview {
    // 미리보기를 위한 더미 workoutID 제공
    TrainSelectionView(workoutID: "dummyWorkoutID")
}
