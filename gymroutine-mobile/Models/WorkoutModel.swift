//
//  WorkoutModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/01/28.
//

import Foundation
import FirebaseFirestore

struct Workout: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let name: String
    let createdAt: Date
    let notes: String?
    let isRoutine: Bool
    let scheduledDays: [String]
    let exercises: [WorkoutExercise]
}
