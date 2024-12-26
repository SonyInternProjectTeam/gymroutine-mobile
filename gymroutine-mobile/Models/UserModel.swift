//
//  UserModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/10/28.
//

import Foundation

// TODO1: have to add birthday & gender

struct User: Decodable {
    var uid: String
    var email: String
    var name: String = ""
    var profilePhoto: String = ""
    var visibility: Int = 2 // 0: 非公開, 1: 友達公開, 2: 全体公開
    var isActive: Bool = false // 運動中なのか
    var createdAt: Date = Date()
}
