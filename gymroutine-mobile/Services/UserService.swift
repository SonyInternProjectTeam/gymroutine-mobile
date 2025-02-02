import Foundation
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth
import UIKit

class UserService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    func getAllUsers() async -> Result<[User], Error> {
        do {
            let querySnapshot = try await db.collection("Users").getDocuments()
            
            let users = try querySnapshot.documents.compactMap { document in
                try document.data(as: User.self)
            }
            
            return .success(users)
        } catch {
            return .failure(error)
        }
    }
    
    func searchUsersByName(name: String) async -> Result<[User], Error> {
        let result = await getAllUsers()
        switch result {
        case .success(let users):
            let filteredUsers = users.filter { $0.name.contains(name) }
            return .success(filteredUsers)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func uploadProfilePhoto(userID: String, image: UIImage) async -> String? {
            let storageRef = storage.reference().child("profile_photos/\(userID).jpg")
            guard let imageData = image.jpegData(compressionQuality: 0.3) else { return nil }
            
            do {
                _ = try await storageRef.putDataAsync(imageData, metadata: nil)
                let downloadURL = try await storageRef.downloadURL()
                
                try await db.collection("Users").document(userID).updateData([
                    "profilePhoto": downloadURL.absoluteString
                ])
                
                print("✅ Successfully updated profile photo!")
                return downloadURL.absoluteString
            } catch {
                print("🔥 Error uploading profile photo: \(error.localizedDescription)")
                return nil
            }
        }
}
