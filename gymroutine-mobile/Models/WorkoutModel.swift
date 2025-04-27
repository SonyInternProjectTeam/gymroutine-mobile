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
    
    static var mock: Workout {
        Workout(
            id: UUID().uuidString,
            userId: "mockUserId123",
            name: "Chest Day Workout",
            createdAt: Date(),
            notes: "Focus on form, not weight",
            isRoutine: true,
            scheduledDays: ["Monday", "Thursday"],
            exercises: [
                WorkoutExercise.mock()
            ]
        )
    }
}
