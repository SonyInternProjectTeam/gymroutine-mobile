//
//  AuthService.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/10/28.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthService {
    private let db = Firestore.firestore()
    
    // login
    func login(email: String, password: String) -> AnyPublisher<User?, Error> {
        return Future<User?, Error> { promise in
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    promise(.failure(error))
                } else if let authResult = authResult {
                    let user = User(uid: authResult.user.uid, email: authResult.user.email ?? "")
                    promise(.success(user))
                } else {
                    promise(.success(nil))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // signup
    func signup(email: String, password: String, name: String, age: Int, gender: String, birthday: Date) -> AnyPublisher<User?, Error> {
        return Future<User?, Error> { promise in
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    promise(.failure(error))
                } else if let authResult = authResult {
                    let user = User(uid: authResult.user.uid, email: email, name: name, age: age, gender: gender, birthday: birthday)
                    
                    // Firestore save
                    self.db.collection("Users").document(user.uid).setData([
                        "uuid": user.uid,
                        "email": user.email,
                        "name": user.name,
                        "age": user.age,
                        "gender": user.gender,
                        "birthday": Timestamp(date: user.birthday) // timestamp
                    ]) { error in
                        if let error = error {
                            promise(.failure(error))
                        } else {
                            promise(.success(user))
                        }
                    }
                } else {
                    promise(.success(nil))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    
    // logout
    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
}
