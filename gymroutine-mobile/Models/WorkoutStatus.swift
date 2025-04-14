//
//  WorkoutStatus.swift
//  gymroutine-mobile
//
//  Created by 陳品丞 on 2025/04/14.
//

import Foundation

struct WorkoutStats: Codable {
    let totalWorkouts: Int
    let partFrequency: [String: Int]
    let weightProgress: [String: [Double]]
    
    var sortedPartFrequency: [(String, Int)] {
        let sorted = partFrequency.sorted { $0.value > $1.value }
        print("Sorted part frequency: \(sorted)")
        return sorted
    }
    
    var sortedWeightProgress: [(String, [Double])] {
        let sorted = weightProgress.sorted { $0.key < $1.key }
        print("Sorted weight progress: \(sorted)")
        return sorted
    }
    
    func maxWeight(for exercise: String) -> Double {
        weightProgress[exercise]?.max() ?? 0.0
    }
    
    func minWeight(for exercise: String) -> Double {
        weightProgress[exercise]?.min() ?? 0.0
    }
    
    func averageWeight(for exercise: String) -> Double {
        guard let weights = weightProgress[exercise], !weights.isEmpty else { return 0.0 }
        return weights.reduce(0.0, +) / Double(weights.count)
    }
} 
