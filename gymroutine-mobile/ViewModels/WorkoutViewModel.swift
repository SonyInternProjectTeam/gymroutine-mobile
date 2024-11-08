//
//  WorkoutViewModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/11/08.
//

import Foundation
import FirebaseAuth

class WorkoutViewModel: ObservableObject {
    @Published var trainOptions: [String] = []
    private var service = WorkoutService()
    
    func createWorkout() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User is not logged in")
            return
        }
        
        service.createWorkoutDocument(userID: userID) { documentID in
            if let documentID = documentID {
                print("Created workout document with ID: \(documentID)")
                self.fetchTrainOptions() // fetch train options after creating document
            }
        }
    }
    
    func fetchTrainOptions() {
        service.fetchTrainOptions { options in
            DispatchQueue.main.async {
                self.trainOptions = options
            }
        }
    }
}

