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
    // userManagerは@MainActorクラスなので、アクセス時に注意が必要
    // private let userManager = UserManager.shared // 直接アクセスの代わりに必要な場合は関数引数として渡すか、@MainActorコンテキストで使用
    
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
            
            // Attempt to decode User
            let user = try snapshot.data(as: User.self)
            print("✅ Successfully decoded User: \(user.email)") // Add success log
            return .success(user)
        } catch {
            // Log the specific decoding error
            print("🔥 Failed to decode User for uid: \(uid). Error: \(error)")
            // You might want to check the specific error type, e.g., DecodingError
            if let decodingError = error as? DecodingError {
                print("   Decoding Error Details: \(decodingError)")
            }
            return .failure(NSError(domain: "FetchUserError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found or failed to decode."]))
        }
    }
    
    
    /// Firebase Authentication または Firestore 保存
    func createUser(email: String, password: String) -> AnyPublisher<String, Error> {
        return Future<String, Error> { promise in
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    promise(.failure(error))
                } else if let userUID = authResult?.user.uid {
                    // UserManagerのアップデートはここで直接行わず、ログインまたは初期化時に処理
                    // let newUser = User(uid: userUID, email: email) // 未使用変数の削除
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
            
            var userData: [String: Any] = [
                "uid": user.uid,
                "email": user.email,
                "name": user.name,
                "profilePhoto": user.profilePhoto,
                "visibility": user.visibility,
                "isActive": user.isActive,
                "gender": user.gender,
                "createdAt": Timestamp(date: user.createdAt)
            ]
            
            // Add optional fields only if they are not nil
            if let birthday = user.birthday {
                userData["birthday"] = Timestamp(date: birthday)
            }
            if let totalDays = user.totalWorkoutDays {
                userData["totalWorkoutDays"] = totalDays
            }
            if let weight = user.currentWeight {
                userData["currentWeight"] = weight
            }
            if let consecutiveDays = user.consecutiveWorkoutDays {
                userData["consecutiveWorkoutDays"] = consecutiveDays
            }
            if let lastWorkoutDate = user.lastWorkoutDate {
                userData["lastWorkoutDate"] = lastWorkoutDate
            }
            
            // Always set hasAgreedToTerms if it's not nil, default to false if nil
            if let hasAgreedToTerms = user.hasAgreedToTerms {
                userData["hasAgreedToTerms"] = hasAgreedToTerms
                print("✅ Adding hasAgreedToTerms to userData: \(hasAgreedToTerms)")
            } else {
                userData["hasAgreedToTerms"] = false
                print("⚠️ hasAgreedToTerms is nil, setting to false")
            }
            
            print("📊 Final userData before saving: \(userData)")
            
            // Set data (merge is true, so existing fields won't be overwritten unnecessarily)
            try await documentRef.setData(userData, merge: true)
            
            print("✅ Successfully saved user data to Firestore")
            print("🔍 Verifying hasAgreedToTerms was saved...")
            
            // Verify the data was actually saved by reading it back
            let savedDoc = try await documentRef.getDocument()
            if let savedData = savedDoc.data() {
                print("📖 Saved document data: \(savedData)")
                if let savedTermsAgreement = savedData["hasAgreedToTerms"] as? Bool {
                    print("✅ hasAgreedToTerms successfully saved as: \(savedTermsAgreement)")
                } else {
                    print("❌ hasAgreedToTerms NOT found in saved document!")
                }
            }
            
            return .success(())
        } catch {
            print("🔥 Failed to save user data: \(error.localizedDescription)")
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
                    // UserManager has an Auth state listener that will automatically handle authentication changes
                    // No need to manually call initializeUser() here as it causes infinite loops
                    
                    // Return success immediately - the UserManager will handle user data loading via its listener
                    promise(.success(nil)) // Return nil to indicate successful login but data loading in progress
                } else {
                    promise(.failure(NSError(domain: "LoginError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Login failed."])))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    
    
    /// Firebase Authentication - logout
    func logout() {
        // signOutはエラーを投げる可能性があるためtry?を使用
        try? Auth.auth().signOut()
        // ログアウト時にUserManagerの状態を更新（@MainActorで実行）
        Task { @MainActor in
            UserManager.shared.currentUser = nil
            UserManager.shared.isLoggedIn = false
        }
    }
    
    func sendPasswordReset(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    /// Firebase Authentication - delete account
    func deleteAccount() async -> Bool {
        do {
            guard let user = Auth.auth().currentUser else { return false }
            try await user.delete()
            // Sign out after deletion
            try? Auth.auth().signOut()
            Task { @MainActor in
                UserManager.shared.currentUser = nil
                UserManager.shared.isLoggedIn = false
            }
            return true
        } catch {
            print("Error deleting user: \(error)")
            return false
        }
    }
}
