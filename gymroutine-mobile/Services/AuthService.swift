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
    
    /// Firebase Authentication または  Firestore 保存
    func createUser(email: String, password: String) -> AnyPublisher<String, Error> {
            return Future<String, Error> { promise in
                Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                    if let error = error {
                        promise(.failure(error))
                    } else if let userUID = authResult?.user.uid {
                        promise(.success(userUID))
                    } else {
                        promise(.failure(NSError(domain: "SignupError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User creation failed"])))
                    }
                }
            }
            .eraseToAnyPublisher()
        }

        /// Firestore
        func saveUserInfo(uid: String, email:String ,name: String, age: Int, gender: String, birthday: Date) -> AnyPublisher<Void, Error> {
            return Future<Void, Error> { promise in
                self.db.collection("Users").document(uid).setData([
                    "uid": uid,
                    "email": email,
                    "name": name,
                    "age": age,
                    "gender": gender,
                    "birthday": Timestamp(date: birthday)
                ], merge: true) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
            }
            .eraseToAnyPublisher()
        }


    /// Firebase Authentication - login
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
    
    /// Firebase Authentication - logout
    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
}
