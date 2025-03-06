//
//  WorkoutModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/01/28.
//

import Foundation

struct Workout: Identifiable {
    let id: String
    let name: String
    let scheduledDays: [String]
    let createdAt: Date
}
