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
    private let userManager = UserManager.shared
    
    /// Checks if the user is currently logged in and returns their user ID.
    func getCurrentUser() -> FirebaseAuth.User? {
        return Auth.auth().currentUser
    }
    
    func fetchUser(uid: String) async -> Result<User, Error> {
        do {
            let snapshot = try await db
                .collection("Users")
                .document(uid)
                .getDocument()
            return try .success(snapshot.data(as: User.self))
        } catch {
            return .failure(NSError(domain: "FetchUserError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"]))
        }
    }
    
    
    /// Firebase Authentication または Firestore 保存
    func createUser(email: String, password: String) -> AnyPublisher<String, Error> {
        return Future<String, Error> { promise in
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    promise(.failure(error))
                } else if let userUID = authResult?.user.uid {
                    // UserManager Update
                    let newUser = User(uid: userUID, email: email)
                    promise(.success(userUID))
                } else {
                    promise(.failure(NSError(domain: "SignupError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User creation failed"])))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func saveUserInfo(user: User) async -> Result<Void, Error> {
        do {
            let documentRef = db.collection("Users").document(user.uid)
            
            /// TODO 1: ロケーション
            //            if let location = user.location {
            //                userData["location"] = [
            //                    "latitude": location.latitude,
            //                    "longitude": location.longitude
            //                ]
            //            }
            
            let userData: [String: Any] = [
                "uid": user.uid,
                "email": user.email,
                "name": user.name,
                "profilePhoto": user.profilePhoto,
                "visibility": user.visibility,
                "isActive": user.isActive,
                "createdAt": Timestamp(date: user.createdAt)
            ]
            try await documentRef.setData(userData, merge: true)
            return .success(())
        } catch {
            return .failure((NSError(domain: "SaveUserError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User saved failed"])))
        }
    }
    
    
    /// Firebase Authentication - login
    func login(email: String, password: String) -> AnyPublisher<User?, Error> {
        return Future<User?, Error> { promise in
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    promise(.failure(error))
                } else if let _ = authResult {
                    Task {
                        do {
                            // initializeUser 비동기 작업 완료를 명확히 기다림
                            try await UserManager.shared.initializeUser()
                            
                            // UserManager의 상태를 확인하여 Promise 처리
                            DispatchQueue.main.async {
                                if let user = UserManager.shared.currentUser {
                                    promise(.success(user)) // 성공 반환
                                } else {
                                    promise(.failure(NSError(domain: "LoginError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User initialization failed."])))
                                }
                            }
                        } catch {
                            promise(.failure(error)) // 에러 반환
                        }
                    }
                } else {
                    promise(.failure(NSError(domain: "LoginError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Login failed."])))
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
    
    func sendPasswordReset(email: String, birthday: Date, completion: @escaping (Result<Void, Error>) -> Void) {
        self.db.collection("Users").whereField("email", isEqualTo: email).getDocuments { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents, documents.count == 1,
                  let data = documents.first?.data(),
                  let storedBirthday = (data["birthday"] as? Timestamp)?.dateValue() else {
                completion(.failure(NSError(domain: "VerificationError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Verification failed."])))
                return
            }
            
            let calendar = Calendar.current
            if !calendar.isDate(storedBirthday, inSameDayAs: birthday) {
                completion(.failure(NSError(domain: "VerificationError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Verification failed."])))
                return
            }
            
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
}
