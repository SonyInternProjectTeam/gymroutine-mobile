//
//  Workout DetailViewModel.swift
//  gymroutine-mobile
//
//  Created by sony on 2025/01/05.
//

import Foundation
import FirebaseFirestore

class WorkoutDetailViewModel: ObservableObject {
    @Published var workout: Workout? = nil
    private let service = WorkoutService()
    
    func fetchWorkoutDetails(workoutID: String) {
        service.fetchWorkoutDetails(workoutID: workoutID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let workout):
                    self.workout = workout
                case .failure(let error):
                    print("Error fetching workout details: \(error)")
                }
            }
        }
    }
}
