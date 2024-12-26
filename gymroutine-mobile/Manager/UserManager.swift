//
//  UserManager.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/12/26.
//

import Foundation
import FirebaseFirestore

class UserManager: ObservableObject {
    @Published var currentUser: User? = nil
    @Published var isLoggedIn: Bool = false

    private let db = Firestore.firestore()

    static let shared = UserManager() // Single Tone

    private init() {}

    func fetchUserInfo(uid: String, completion: @escaping (Result<User, Error>) -> Void) {
        db.collection("Users").document(uid).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = document?.data() else {
                completion(.failure(NSError(domain: "FetchError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data found for user"])))
                return
            }

            let user = User(
                uid: data["uid"] as? String ?? "",
                email: data["email"] as? String ?? "",
                name: data["name"] as? String ?? "",
                profilePhoto: data["profilePhoto"] as? String ?? "",
                visibility: data["visibility"] as? Int ?? 2,
                isActive: data["isActive"] as? Bool ?? false,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            )

            self.currentUser = user
            self.isLoggedIn = true
            completion(.success(user))
        }
    }
    
    // User login State
    func login(user: User) {
        self.currentUser = user
        self.isLoggedIn = true
    }

    func logout() {
        self.currentUser = nil
        self.isLoggedIn = false
    }
}
