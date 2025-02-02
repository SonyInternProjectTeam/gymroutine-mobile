//
//  UserManager.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/12/26.
//
import Foundation
import FirebaseAuth
import FirebaseFirestore

class UserManager: ObservableObject {
    @Published var currentUser: User? = nil
    @Published var isLoggedIn: Bool = false
    
    private let db = Firestore.firestore()
    
    static let shared = UserManager() // Singleton
    
    private init() {}
    
    func initializeUser() async {
        guard let authUser = Auth.auth().currentUser else {
            print("No logged-in user found.")
            return
        }
        
        do {
            let user = try await fetchUserInfo(uid: authUser.uid)
            DispatchQueue.main.async {
                self.currentUser = user
                self.isLoggedIn = true
            }
        } catch {
            print("Failed to fetch user info: \(error)")
        }
    }
    
    func fetchUserInfo(uid: String) async throws -> User {
        let document = try await db.collection("Users").document(uid).getDocument()
        guard let data = document.data() else {
            throw NSError(domain: "FetchError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data found for user"])
        }
        
        return User(
            uid: data["uid"] as? String ?? "",
            email: data["email"] as? String ?? "",
            name: data["name"] as? String ?? "",
            profilePhoto: data["profilePhoto"] as? String ?? "",
            visibility: data["visibility"] as? Int ?? 2,
            isActive: data["isActive"] as? Bool ?? false,
            birthday: (data["birthday"] as? Timestamp)?.dateValue(),
            gender: data["gender"] as? String ?? "",
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
    
    // follower
    func fetchFollowersCount(userId: String) async -> Int {
        do {
            let snapshot = try await db.collection("Users").document(userId).collection("Followers").getDocuments()
            return snapshot.documents.count
        } catch {
            print("[ERROR] フォロワー数の取得に失敗。id: \(userId)")
            return -1
        }
    }
    
    // following
    func fetchFollowingCount(userId: String) async -> Int {
        do {
            let snapshot = try await db.collection("Users").document(userId).collection("Following").getDocuments()
            return snapshot.documents.count
        } catch {
            print("[ERROR] フォロー数の取得に失敗。id: \(userId)")
            return -1
        }
    }
}

