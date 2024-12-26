//
//  UserModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/10/28.
//

import Foundation

struct User: Decodable {
    var uid: String
    var email: String
    var name: String = ""
    var age: Int = 0
    var gender: String = ""
    var birthday: Date = Date() // 기본값은 현재 날짜로 설정
}
