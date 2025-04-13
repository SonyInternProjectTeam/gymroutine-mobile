//
//  UserModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/10/28.
//

import Foundation

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
<<<<<<< HEAD
    
    /// 年齢を計算する
    var age: Int {
        guard let birthday = birthday else { return 0 }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: Date())
        return ageComponents.year ?? 0
=======

    init(uid: String, email: String, name: String = "", profilePhoto: String = "", visibility: Int = 2, isActive: Bool = false, birthday: Date? = nil, gender: String = "", createdAt: Date = Date()) {
        self.uid = uid
        self.email = email
        self.name = name
        self.profilePhoto = profilePhoto
        self.visibility = visibility
        self.isActive = isActive
        self.birthday = birthday
        self.gender = gender
        self.createdAt = createdAt
>>>>>>> SP9-3Workout
    }
}
