//
//  UserManager.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/12/26.
//
import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine // Import Combine

@MainActor
final class UserManager: ObservableObject { // Make final
    static let shared = UserManager()
    
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false // Restore isLoggedIn
    @Published var isLoading: Bool = true // Add loading state
    @Published var hasAgreedToTerms: Bool = false // Track terms agreement
    
    private var userListener: ListenerRegistration? // Firestore listener
    private var cancellables = Set<AnyCancellable>() // For Combine subscriptions
    
    private let db = Firestore.firestore() // Keep if used elsewhere
    
    private init() {
        print("DEBUG: UserManager init - Setting up Auth listener")
        // Observe Firebase Auth state changes to automatically manage user session
        Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            print("DEBUG: Auth state changed. Firebase user: \(user?.uid ?? "nil")")
            Task {
                // Handle user login/logout
                await self.handleAuthStateChange(firebaseUser: user)
            }
        }
        // Initial check in case the listener fires late or misses the initial state
        Task { 
            await handleAuthStateChange(firebaseUser: Auth.auth().currentUser)
        }
    }
    
    deinit {
        // Clean up the listener when UserManager is deallocated
        userListener?.remove()
        print("DEBUG: UserManager deinit, listener removed.")
    }
    
    // Handles authentication state changes from Firebase Auth
    private func handleAuthStateChange(firebaseUser: FirebaseAuth.User?) async {
        if let firebaseUser = firebaseUser {
            print("DEBUG: User is authenticated. UID: \(firebaseUser.uid)")
            // Setup listener only if not already listening for this user
            if currentUser?.uid != firebaseUser.uid || userListener == nil {
                await self.setupUserListener(userId: firebaseUser.uid)
                await self.waitForUserData()
            }
            // Update isLoggedIn along with isUserAuthenticated
            if !self.isLoggedIn { self.isLoggedIn = true } 
            // isLoading will be set to false within setupUserListener
        } else {
            print("DEBUG: User is not authenticated.")
            // 로그아웃 알림 전송
            if self.currentUser != nil {
                NotificationCenter.default.post(name: NSNotification.Name("UserLoggedOut"), object: nil)
            }
            
            // Update isLoggedIn along with isUserAuthenticated
            if self.isLoggedIn { self.isLoggedIn = false } 
            self.currentUser = nil // Clear user data
            self.userListener?.remove() // Remove listener
            self.userListener = nil // Ensure listener reference is cleared
            self.isLoading = false // Stop loading
        }
    }
    
    // Sets up the real-time listener for the current user's document
    private func setupUserListener(userId: String) async {
        userListener?.remove() // Ensure no duplicate listeners
        isLoading = true // Indicate loading started
        
        print("DEBUG: Setting up Firestore listener for user: \(userId)")
        let userRef = db.collection("Users").document(userId)
        
        userListener = userRef.addSnapshotListener { [weak self] (documentSnapshot, error) in
            guard let self = self else { 
                print("DEBUG: UserManager listener callback - self is nil")
                return 
            }
            // Defer setting isLoading to false until data is processed or error occurs
            
            if let error = error {
                print("ERROR: Listening for user document failed: \(error.localizedDescription)")
                // Consider how to handle listener errors (e.g., retry? keep old data?)
                self.currentUser = nil // Clear data on error
                self.isLoading = false
                return
            }
            
            guard let document = documentSnapshot else {
                print("ERROR: User document snapshot is nil (potential Firestore issue)")
                self.currentUser = nil
                self.isLoading = false
                return
            }
            
            if !document.exists {
                print("DEBUG: User document does not exist for UID: \(userId). User might need creation flow.")
                self.currentUser = nil 
                self.isLoading = false
            } else {
                do {
                    // Attempt to decode the document into a User object
                    let user = try document.data(as: User.self)
                    // Only update if the decoded user is different from the current one
                    if self.currentUser != user { // Requires User to be Equatable
                         self.currentUser = user
                         self.hasAgreedToTerms = user.hasAgreedToTerms ?? false
                         print("DEBUG: User data UPDATED via listener: Name=\(user.name ?? "N/A"), Total=\(user.totalWorkoutDays ?? -1), Consec=\(user.consecutiveWorkoutDays ?? -1), HasAgreedToTerms=\(user.hasAgreedToTerms ?? false)")
                         
                         // 로그인 알림 전송
                         NotificationCenter.default.post(name: NSNotification.Name("UserLoggedIn"), object: user)
                    } else {
                         print("DEBUG: User data received via listener, but NO changes detected.")
                    }
                } catch {
                    print("ERROR: Failed to decode user data (check User model against Firestore): \(error.localizedDescription)")
                    self.currentUser = nil // Clear data on decoding error
                }
                self.isLoading = false // Loading finished after processing
            }
        }
    }
    
    // Allows external services (like UserService) to ensure user data is being listened to
    // It primarily checks if the listener is active for the given userId.
    func fetchInitialUserData(userId: String) async {
        print("DEBUG: fetchInitialUserData called for \(userId). Current user: \(self.currentUser?.uid ?? "nil"), Listener exists: \(self.userListener != nil)")
        // Ensure listener is running for the correct user, especially if called before auth state change completes
        if self.currentUser?.uid != userId || self.userListener == nil {
             print("DEBUG: Listener not active or for wrong user. Setting up listener for \(userId)")
             await setupUserListener(userId: userId)
        } else {
             print("DEBUG: Listener already active for \(userId)")
             // If already listening, data should arrive automatically. 
             // Optionally force a re-fetch if immediate data is critical (though listener should handle it)
             // self.isLoading = false // We might already have data
        }
    }
    
    func waitForUserData() async {
        await withCheckedContinuation { continuation in
            var observer: NSObjectProtocol? = nil 

            observer = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("UserLoggedIn"),
                object: nil,
                queue: .main
            ) { notification in
                if let user = notification.object as? User {
                    print("User data received: \(user.name ?? "Unknown")")
                }
                // 続きを再開
                continuation.resume()
                // メモリリーク防止のため解除
                if let observer = observer {
                    NotificationCenter.default.removeObserver(observer)
                }
            }
        }
    }
    
    // Logs out the current user
    func signOut() {
        print("DEBUG: Signing out user...")
        do {
            try Auth.auth().signOut()
            // The Auth state listener (handleAuthStateChange) will automatically handle cleanup 
            // (removing listener, clearing currentUser, setting isLoggedIn to false)
        } catch let signOutError as NSError {
            print("ERROR: Signing out failed: %@", signOutError)
        }
    }

    // --- Deprecated / Replaced by Listener --- 
    // Keep initializeUser for potential entry point logic, but it now mainly relies on handleAuthStateChange
    func initializeUser() async { 
         guard let authUser = Auth.auth().currentUser else {
             print("No logged-in user found during initializeUser.")
             await handleAuthStateChange(firebaseUser: nil) // Ensure state is handled correctly
             return
         }
         print("DEBUG: initializeUser called for user \(authUser.uid)")
         await handleAuthStateChange(firebaseUser: authUser) // Trigger state handling
     }
     
    // fetchUserInfo can still be useful for fetching *other* users' profiles, 
    // but should not be the primary way to get the *current* logged-in user's data.
    func fetchUserInfo(uid: String) async throws -> User {
         print("DEBUG: fetchUserInfo called for uid: \(uid) (Use listener for current user)")
         let document = try await db.collection("Users").document(uid).getDocument()
         guard document.exists else {
             throw NSError(domain: "FetchError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User document not found for uid: \(uid)"])
         }
         let user = try document.data(as: User.self)
         print("DEBUG: fetchUserInfo successfully decoded user: \(user.name ?? "N/A")")
         return user 
     }
     
    // Updating isActive: Listener will handle the update to currentUser automatically
    func updateUserActiveStatus(isActive: Bool) async -> Result<Void, Error> {
        guard let uid = Auth.auth().currentUser?.uid else {
            return .failure(NSError(domain: "UserError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
        }
        
        do {
            try await db.collection("Users").document(uid).updateData(["isActive": isActive])
            print("[UserManager] Update request for isActive=\(isActive) sent. Listener will handle local update.")
            return .success(())
        } catch {
            print("[UserManager] Failed to update isActive status: \(error.localizedDescription)")
            return .failure(error)
        }
    }

    func fetchFollowersCount(userId: String) async -> Int {
        do {
            // Consider adding error handling or returning Result<Int, Error>
            let snapshot = try await db.collection("Users").document(userId).collection("Followers").getDocuments()
            return snapshot.documents.count
        } catch {
            print("[ERROR] Failed to fetch followers count for id: \(userId). Error: \(error.localizedDescription)")
            return 0 // Return 0 on error or handle differently
        }
    }
    
    // following count
    func fetchFollowingCount(userId: String) async -> Int {
        do {
            // Consider adding error handling or returning Result<Int, Error>
            let snapshot = try await db.collection("Users").document(userId).collection("Following").getDocuments()
            return snapshot.documents.count
        } catch {
            print("[ERROR] Failed to fetch following count for id: \(userId). Error: \(error.localizedDescription)")
            return 0 // Return 0 on error or handle differently
        }
    }
}

