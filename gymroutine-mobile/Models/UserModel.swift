//
//  UserModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/10/28.
//

import Foundation
import FirebaseFirestore // Import for Timestamp

// Structure for weight history entries
struct WeightEntry: Codable, Hashable { // Codable and Hashable for potential future use
    var weight: Double
    var date: Timestamp // Use Timestamp for Firestore compatibility
}

struct User: Decodable, Identifiable, Equatable { // Add Equatable conformance
    var id: String { uid }
    var uid: String
    var email: String
    var name: String = ""
    var profilePhoto: String = ""
    var visibility: Int = 2 // 0: 非公開, 1: 友達公開, 2: 全体公開
    var isActive: Bool = false // 運動中なのか
    var birthday: Date? = nil // birthday
    var gender: String = "" // gender
    var createdAt: Date = Date()

    // New fields - Make fields potentially missing in Firestore optional
    var totalWorkoutDays: Int? = 0 // Changed to Optional Int
    var currentWeight: Double? = nil // Already Optional
    var consecutiveWorkoutDays: Int? = 0 // Changed to Optional Int
    var weightHistory: [WeightEntry]? = [] // Changed to Optional Array, default empty array still handles missing data upon creation
    var lastWorkoutDate: String? // Add lastWorkoutDate field (String)

    init(uid: String, email: String, name: String = "", profilePhoto: String = "", visibility: Int = 2, isActive: Bool = false, birthday: Date? = nil, gender: String = "", createdAt: Date = Date(), totalWorkoutDays: Int? = 0, currentWeight: Double? = nil, consecutiveWorkoutDays: Int? = 0, weightHistory: [WeightEntry]? = [], lastWorkoutDate: String? = nil) {
        self.uid = uid
        self.email = email
        self.name = name
        self.profilePhoto = profilePhoto
        self.visibility = visibility
        self.isActive = isActive
        self.birthday = birthday
        self.gender = gender
        self.createdAt = createdAt
        // Initialize new fields
        self.totalWorkoutDays = totalWorkoutDays
        self.currentWeight = currentWeight
        self.consecutiveWorkoutDays = consecutiveWorkoutDays
        self.weightHistory = weightHistory
        self.lastWorkoutDate = lastWorkoutDate // Initialize lastWorkoutDate
    }
    
    // Implement Equatable: Compare users based on their unique ID (uid)
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.uid == rhs.uid
    }
}
