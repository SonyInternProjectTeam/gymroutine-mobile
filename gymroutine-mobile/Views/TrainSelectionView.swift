//
//  TrainSelectionView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/11/08.
//

import SwiftUI

struct TrainSelectionView: View {
    @ObservedObject var viewModel = WorkoutViewModel()
    
    var body: some View {
        VStack {
            Text("Choose a Workout")
                .font(.title)
                .padding()
            
            List(viewModel.trainOptions, id: \.self) { option in
                Text(option)
            }
            
            Spacer()
        }
        .onAppear {
            viewModel.createWorkout()
        }
        .navigationTitle("Train Selection")
    }
}

#Preview {
    TrainSelectionView()
}
