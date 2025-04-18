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
    // userManager는 @MainActor 클래스이므로 접근 시 주의 필요
    // private let userManager = UserManager.shared // 직접 접근 대신 필요 시 함수 인자로 전달하거나 @MainActor 컨텍스트에서 사용
    
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
                    // UserManager 업데이트는 여기서 직접 하지 않고, 로그인 또는 초기화 시 처리
                    // let newUser = User(uid: userUID, email: email) // 변수 미사용 제거
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
            
            let userData: [String: Any] = [
                "uid": user.uid,
                "email": user.email,
                "name": user.name,
                "profilePhoto": user.profilePhoto,
                "visibility": user.visibility,
                "isActive": user.isActive,
                // birthday가 nil이 아니면 Timestamp로 변환, nil이면 NSNull() 또는 필드 제거
                "birthday": user.birthday != nil ? Timestamp(date: user.birthday!) : NSNull(),
                "gender": user.gender,
                "createdAt": Timestamp(date: user.createdAt)
            ]
            
            // NSNull 대신 필드를 제거하는 방법
            // if let birthday = user.birthday {
            //     userData["birthday"] = Timestamp(date: birthday)
            // }
            
            try await documentRef.setData(userData, merge: true)
            
            // Initialize UserManager after saving - @MainActor 컨텍스트에서 호출 필요
            // await UserManager.shared.initializeUser() // 호출하는 쪽에서 처리하도록 변경
            
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
                        // initializeUser는 @MainActor 함수이므로 await 필요
                        await UserManager.shared.initializeUser()
                        
                        // initializeUser 호출 후 상태 확인 (@MainActor)
                        let user = await UserManager.shared.currentUser
                        if let user = user {
                            promise(.success(user))
                        } else {
                            // initializeUser가 성공했지만 user가 nil인 경우 (드물지만 처리)
                            promise(.failure(NSError(domain: "LoginError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User initialization failed."])))
                        }
                        // initializeUser 자체에서 발생하는 에러는 내부에서 처리되므로 여기서 catch 불필요
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
        // signOut은 에러를 던질 수 있으므로 try? 사용
        try? Auth.auth().signOut()
        // 로그아웃 시 UserManager 상태 업데이트 (@MainActor에서 실행)
        Task { @MainActor in
            UserManager.shared.currentUser = nil
            UserManager.shared.isLoggedIn = false
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
