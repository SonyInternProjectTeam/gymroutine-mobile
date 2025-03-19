//
//  NewExeciseSearchView.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2025/03/16
//  
//

import SwiftUI

struct NewExerciseSearchView: View {
    
    private let isReadOnly: Bool
    @ObservedObject var execisesManager: WorkoutExecisesManager
    @StateObject private var viewModel = ExerciseSearchViewModel()
    private let exerciseColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible())
    ]
    
    init(execisesManager: WorkoutExecisesManager? = nil) {
        self.isReadOnly = execisesManager == nil
        self.execisesManager = execisesManager ?? WorkoutExecisesManager()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    ExerciseSearchField(text:$viewModel.searchWord)
                        .onSubmit {
                            viewModel.searchExerciseName(for: viewModel.searchWord)
                        }
                    
                    filterBox
                    
                    exerciseGridView
                }
                .padding()
            }
            .background(.gray.opacity(0.03))
        }
    }
    
    private var CategoryView: some View {
        HStack {
            Text("カテゴリ")
                .font(.title2)
                .fontWeight(.bold)
                .hAlign(.leading)

            Button {
            } label: {
                ExercisePartToggle(exercisePart: viewModel.selectedExercisePart)
            }
        }
    }
    
    private var filterBox: some View {
        HStack {
            Toggle(isOn: $viewModel.isBoolmarkOnly) {
                Text("ブックマークのみ")
                    .font(.body)
            }
            .tint(.main)
            .toggleStyle(.checkBox)
            
            Button {
            } label: {
                ExercisePartToggle(exercisePart: viewModel.selectedExercisePart)
            }
        }
    }
    
    
    private var exerciseGridView: some View {
        VStack (alignment: .leading, spacing: 16) {
            Text("おすすめ")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: exerciseColumns, spacing: 12) {
                ForEach(viewModel.filterExercises, id: \.self) { exercise in
                    NavigationLink {
                        NewExerciseDetailView(
                            exercise: exercise,
                            isReadOnly: isReadOnly,
                            onAddButtonTapped: {
                                execisesManager.appendExercise(exercise: exercise)
                            }
                        )
                    } label: {
                        ExerciseGridCell(exercise: exercise, onTapPlusButton: {
                            execisesManager.appendExercise(exercise: exercise)
                        })
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

#Preview {
    NewExerciseSearchView()
}
