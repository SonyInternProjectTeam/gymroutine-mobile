//
//  Router.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2024/12/26
//  
//

import Foundation
import SwiftUI

enum RouteType {
    case splash //アプリ名表示、データの確認
    case welcome    //新規登録かログインかの画面
    case initProfileSetup    //ユーザー情報入力画面
    case main(user: User)   //メイン画面
}

@MainActor
final class Router: ObservableObject {
    @Published var route = RouteType.splash

    func switchRootView(to routeType: RouteType) {
        route = routeType
    }
}
