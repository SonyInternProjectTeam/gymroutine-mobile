//
//  WorkoutSortView.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2025/04/27
//  
//

import SwiftUI

struct WorkoutSortView: View {
    
    @EnvironmentObject var viewModel: WorkoutDetailViewModel
    private let analyticsService = AnalyticsService.shared
    
    var body: some View {
        List {
            ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { index, exercise in
                HStack(spacing: 16) {
                    Text("\(index + 1)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding()
                        .background(.main)
                        .clipShape(Circle())
                    
                    ExerciseImageCell(imageName: exercise.key)
                        .frame(width: 56, height: 56)
                    
                    VStack(alignment: .leading) {
                        Text(exercise.toPartName())
                            .font(.caption)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.secondary.opacity(0.4), lineWidth: 2)
                            )
                        
                        Text(exercise.name)
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.1)
                    }
                }
            }
            .onMove(perform: viewModel.moveExercise)
            .listRowBackground(Color.clear)
        }
        .environment(\.editMode, .constant(.active))
        .onAppear {
            // Log screen view
            analyticsService.logScreenView(screenName: "WorkoutSort")
        }
    }
}

#Preview {
    WorkoutSortView()
        .environmentObject(WorkoutDetailViewModel(workout: Workout.mock))
}
