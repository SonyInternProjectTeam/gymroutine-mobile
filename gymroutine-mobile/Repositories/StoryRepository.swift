import FirebaseFirestore
import Combine

class StoryRepository {
    static let shared = StoryRepository()
    private let storiesCollection = Firestore.firestore().collection("Stories")

    private func storyDocument(storyId: String) -> DocumentReference {
        storiesCollection.document(storyId)
    }

    func fetchFriendsStories(userIds: [String]) -> AnyPublisher<[Story], Error> {
        Future<[Story], Error> { promise in
            guard !userIds.isEmpty else {
                print("[StoryRepository] User ID list is empty, returning empty array.")
                promise(.success([]))
                return
            }

            let now = Timestamp()
            print("[StoryRepository] Fetching stories for user IDs: \(userIds)")

            self.storiesCollection
                .whereField("userId", in: userIds)
                .whereField("isExpired", isEqualTo: false)
                .whereField("expireAt", isGreaterThan: now)
                .order(by: "expireAt", descending: true)
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("[StoryRepository] Error fetching documents: \(error.localizedDescription)")
                        promise(.failure(error))
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        print("[StoryRepository] No documents found in snapshot.")
                        promise(.success([]))
                        return
                    }
                    
                    print("[StoryRepository] Fetched \(documents.count) documents matching query.")

                    var stories: [Story] = []
                    var decodingErrors = 0
                    for document in documents {
                        do {
                            let story = try document.data(as: Story.self)
                            stories.append(story)
                        } catch {
                            print("[StoryRepository] Error decoding document \(document.documentID): \(error)")
                            decodingErrors += 1
                        }
                    }
                    
                    print("[StoryRepository] Successfully decoded \(stories.count) stories. Failed to decode \(decodingErrors) documents.")
                    promise(.success(stories))
                }
        }
        .eraseToAnyPublisher()
    }
    
    // TODO: Add functions to fetch user's own stories, potentially fetch single story by ID if needed
}
