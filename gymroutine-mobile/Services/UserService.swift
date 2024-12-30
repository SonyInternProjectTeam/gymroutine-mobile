import FirebaseFirestore

class UserService {
    private let db = Firestore.firestore()
    
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
}
