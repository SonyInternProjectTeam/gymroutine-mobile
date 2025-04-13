import FirebaseFirestore

struct Story: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    let userId: String
    let photo: String? // Optional photo URL
    let expireAt: Timestamp
    var isExpired: Bool
    let visibility: Int // 0: Private, 1: Friends, 2: Public
    let workoutId: String // Associated workout result ID
    let createdAt: Timestamp

    // Add coding keys if Firestore field names differ from struct properties
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case photo
        case expireAt
        case isExpired
        case visibility
        case workoutId
        case createdAt // Assuming Firestore uses "createdAt" (lowercase c)
        // case createdAt = "CreatedAt" // If Firestore uses "CreatedAt" (uppercase C)
    }
} 
