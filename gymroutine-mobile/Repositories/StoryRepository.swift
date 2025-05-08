import FirebaseFirestore
import Combine

class StoryRepository {
    static let shared = StoryRepository()
    private let storiesCollection = Firestore.firestore().collection("Stories")
    private var listeners: [String: ListenerRegistration] = [:]

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
    
    // 스토리 실시간 리스너 (추가, 삭제, 변경 감지)
    func listenForFriendsStories(userIds: [String], onUpdate: @escaping ([Story]) -> Void, onError: @escaping (Error) -> Void) -> String {
        guard !userIds.isEmpty else {
            print("[StoryRepository] User ID list is empty for listener, returning.")
            onUpdate([])
            return ""
        }

        let now = Timestamp()
        print("[StoryRepository] Setting up listener for stories from user IDs: \(userIds)")
        
        // 고유 리스너 ID 생성
        let listenerId = UUID().uuidString
        
        // 리스너 설정
        let listener = self.storiesCollection
            .whereField("userId", in: userIds)
            .whereField("isExpired", isEqualTo: false)
            .whereField("expireAt", isGreaterThan: now)
            .order(by: "expireAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("[StoryRepository] Listener error: \(error.localizedDescription)")
                    onError(error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("[StoryRepository] No documents in listener snapshot.")
                    onUpdate([])
                    return
                }
                
                print("[StoryRepository] Listener update with \(documents.count) documents.")
                
                var stories: [Story] = []
                var decodingErrors = 0
                
                for document in documents {
                    do {
                        let story = try document.data(as: Story.self)
                        stories.append(story)
                    } catch {
                        print("[StoryRepository] Error decoding document in listener \(document.documentID): \(error)")
                        decodingErrors += 1
                    }
                }
                
                print("[StoryRepository] Listener successfully decoded \(stories.count) stories. Failed to decode \(decodingErrors) documents.")
                onUpdate(stories)
            }
        
        // 리스너 저장
        listeners[listenerId] = listener
        return listenerId
    }
    
    // 리스너 제거
    func removeListener(listenerId: String) {
        if let listener = listeners[listenerId] {
            listener.remove()
            listeners.removeValue(forKey: listenerId)
            print("[StoryRepository] Removed listener with ID: \(listenerId)")
        }
    }
    
    // 모든 리스너 제거
    func removeAllListeners() {
        for (id, listener) in listeners {
            listener.remove()
            print("[StoryRepository] Removed listener with ID: \(id)")
        }
        listeners.removeAll()
        print("[StoryRepository] All listeners removed")
    }
    
    // TODO: Add functions to fetch user's own stories, potentially fetch single story by ID if needed
}