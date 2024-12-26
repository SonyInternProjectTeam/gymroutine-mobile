//
//  WelcomeViewModel.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2024/12/26
//  
//

import Foundation

@MainActor
final class WelcomeViewModel: ObservableObject {
    
    private let router: Router
    
    init(router: Router) {
        self.router = router
    }
}
