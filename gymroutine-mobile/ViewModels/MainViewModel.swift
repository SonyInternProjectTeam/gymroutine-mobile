//
//  MainViewModel.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2024/12/26
//  
//

import Foundation
import FirebaseAuth

@MainActor
final class MainViewModel: ObservableObject {
    
    private let router: Router
    
    init(router: Router) {
        self.router = router
    }
}
