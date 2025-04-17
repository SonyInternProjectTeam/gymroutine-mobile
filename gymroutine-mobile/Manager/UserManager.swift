//
//  UserManager.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/12/26.
//
import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
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
            self.currentUser = user
            self.isLoggedIn = true
        } catch {
            print("Failed to fetch user info: \(error)")
            self.currentUser = nil
            self.isLoggedIn = false
        }
    }
    
    func fetchUserInfo(uid: String) async throws -> User {
        let document = try await db.collection("Users").document(uid).getDocument()
        guard let data = document.data() else {
            throw NSError(domain: "FetchError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data found for user"])
        }
        
        // Decode WeightHistory manually if needed, assuming it's an array of maps
        let weightHistoryData = data["weightHistory"] as? [[String: Any]] ?? []
        var weightHistoryEntries: [WeightEntry] = []
        for entryData in weightHistoryData {
            if let weight = entryData["weight"] as? Double,
               let dateTimestamp = entryData["date"] as? Timestamp {
                weightHistoryEntries.append(WeightEntry(weight: weight, date: dateTimestamp))
            }
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
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            totalWorkoutDays: data["totalWorkoutDays"] as? Int,
            currentWeight: data["currentWeight"] as? Double,
            consecutiveWorkoutDays: data["consecutiveWorkoutDays"] as? Int,
            weightHistory: weightHistoryEntries, // Pass the decoded array
            lastWorkoutDate: data["lastWorkoutDate"] as? String // Fetch and pass lastWorkoutDate
        )
    }
    
    // 사용자의 운동 활성 상태(isActive) 업데이트
    func updateUserActiveStatus(isActive: Bool) async -> Result<Void, Error> {
        guard let uid = Auth.auth().currentUser?.uid else {
            return .failure(NSError(domain: "UserError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
        }
        
        do {
            try await db.collection("Users").document(uid).updateData(["isActive": isActive])
            
            // 로컬 currentUser 객체도 업데이트
            if var updatedUser = self.currentUser {
                updatedUser.isActive = isActive
                self.currentUser = updatedUser
            }
            
            print("[UserManager] 사용자 isActive 상태를 \(isActive)로 업데이트 완료")
            return .success(())
        } catch {
            print("[UserManager] 사용자 isActive 상태 업데이트 실패: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    // TODO : Service or Repoに移動するべき
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

