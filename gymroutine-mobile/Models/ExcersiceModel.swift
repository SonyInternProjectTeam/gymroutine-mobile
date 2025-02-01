//
//  ExerciseModel.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2024/12/13.
//

import Foundation

struct Exercise:Codable,Hashable {
    var name: String = ""
    var description: String = ""
    var img: String = ""
    var part: String = ""
    
    func toExercisePart () -> ExercisePart? {
        return ExercisePart(rawValue: part)
    }
}

struct WorkoutExercise: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var description: String
    var img: String
    var part: String
    var sets: Int
    var reps: Int
    var weight: Int
}


enum ExercisePart: String, CaseIterable {
    case arm
    case chest
    case back
    case legs
}
