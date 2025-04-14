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

struct User: Decodable, Identifiable {
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

    // New fields
    var totalWorkoutDays: Int = 0
    var currentWeight: Double? = nil // Optional, as user might not enter it initially
    var consecutiveWorkoutDays: Int = 0
    var weightHistory: [WeightEntry] = [] // Array of WeightEntry

    init(uid: String, email: String, name: String = "", profilePhoto: String = "", visibility: Int = 2, isActive: Bool = false, birthday: Date? = nil, gender: String = "", createdAt: Date = Date(), totalWorkoutDays: Int = 0, currentWeight: Double? = nil, consecutiveWorkoutDays: Int = 0, weightHistory: [WeightEntry] = []) {
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
    }
}
