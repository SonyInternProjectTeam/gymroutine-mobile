//
//  TrainSelectionView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/11/08.
//

import SwiftUI

struct TrainSelectionView: View {
    @ObservedObject var viewModel = WorkoutViewModel()
    @State private var selectedTrain: String? = nil
    @State private var selectedExercise: String? = nil
    
    var body: some View {
        VStack {
            Text("Choose a Workout")
                .font(.title)
                .padding()
            
            List(viewModel.trainOptions, id: \.self) { option in
                Button(action: {
                    selectedTrain = option
                    viewModel.fetchExercises(for: option)
                }) {
                    Text(option)
                }
            }
            
            if let selectedTrain = selectedTrain {
                Text("Exercises for \(selectedTrain)")
                    .font(.headline)
                    .padding()
                
                List(viewModel.exercises, id: \.self) { exercise in
                    Button(action: {
                        selectedExercise = exercise
                        viewModel.addExerciseToWorkout(exerciseName: exercise, part: selectedTrain)
                    }) {
                        Text(exercise)
                    }
                }
            }
            
            Spacer()
        }
        .onAppear {
            viewModel.createWorkout()
            viewModel.fetchTrainOptions()
        }
        .navigationTitle("Train Selection")
    }
}

#Preview {
    TrainSelectionView()
}

