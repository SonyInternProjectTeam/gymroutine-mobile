import Combine
import Firebase

class StoryService {
    static let shared = StoryService()
    private let repository = StoryRepository.shared
    private let followService = FollowService() // 新しいインスタンスを作成
    private var cancellables = Set<AnyCancellable>()
    private var storyListenerId: String? // ストーリーリスナーIDを保存
    
    @Published var friendsStories: [Story] = []
    @Published var userStories: [Story] = [] // ユーザー自身のストーリー用
    
    deinit {
        // オブジェクトが解放される時にすべてのリスナーをクリア
        if let listenerId = storyListenerId {
            repository.removeListener(listenerId: listenerId)
        }
    }
    
    func fetchFriendsStories(userId: String) {
        Task {
            // 1. Get following User objects from FollowService using async/await
            let result = await followService.getFollowing(for: userId)
            
            switch result {
            case .success(let followingUsers):
                // Extract user IDs from the User objects
                let friendIds = followingUsers.map { $0.uid }
                
                // 2. Fetch stories for those friend IDs using StoryRepository
                // Pass the current user's ID directly
                fetchStories(for: friendIds, currentUserId: userId)
                
            case .failure(let error):
                print("Error fetching following users: \(error.localizedDescription)")
                // Handle error appropriately
                await MainActor.run { // Ensure UI updates on main thread
                    self.friendsStories = []
                }
            }
        }
    }
    
    // 実時間ストーリー更新のためのメソッド
    func startRealtimeUpdates(userId: String) {
        Task {
            // 既存のリスナーがあれば削除
            if let listenerId = storyListenerId {
                repository.removeListener(listenerId: listenerId)
            }
            
            // フォローしているユーザーを取得
            let result = await followService.getFollowing(for: userId)
            
            switch result {
            case .success(let followingUsers):
                let friendIds = followingUsers.map { $0.uid }
                setupStoryListener(for: friendIds, currentUserId: userId)
                
            case .failure(let error):
                print("Error fetching following users for realtime updates: \(error.localizedDescription)")
                await MainActor.run {
                    self.friendsStories = []
                }
            }
        }
    }
    
    // ストーリーリスナー設定
    private func setupStoryListener(for userIds: [String], currentUserId: String?) {
        // 現在のユーザーIDを含める
        var idsToFetch = userIds
        if let safeCurrentUserId = currentUserId, !idsToFetch.contains(safeCurrentUserId) {
            idsToFetch.append(safeCurrentUserId)
        }
        
        guard !idsToFetch.isEmpty else {
            print("No user IDs to listen for stories.")
            DispatchQueue.main.async {
                self.friendsStories = []
            }
            return
        }
        
        print("Setting up realtime listener for stories from user IDs: \(idsToFetch)")
        
        // 新しいリスナーを設定
        storyListenerId = repository.listenForFriendsStories(
            userIds: idsToFetch,
            onUpdate: { [weak self] stories in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.friendsStories = stories
                    print("Realtime update: \(stories.count) stories received")
                }
            },
            onError: { error in
                print("Error in realtime story updates: \(error.localizedDescription)")
            }
        )
    }
    
    // リスナー停止
    func stopRealtimeUpdates() {
        if let listenerId = storyListenerId {
            repository.removeListener(listenerId: listenerId)
            storyListenerId = nil
            print("Stopped realtime story updates")
        }
    }
    
    // Helper function to fetch stories using Combine after getting IDs
    // Accepts currentUserId as a parameter
    private func fetchStories(for userIds: [String], currentUserId: String?) {
        // Always include the current user's ID in the fetch request
        var idsToFetch = userIds
        if let safeCurrentUserId = currentUserId, !idsToFetch.contains(safeCurrentUserId) {
            idsToFetch.append(safeCurrentUserId)
        }
        
        guard !idsToFetch.isEmpty else {
            print("No user IDs to fetch stories for.")
            // Clear stories if the list is empty (e.g., user has no friends and no self stories)
            DispatchQueue.main.async { // Ensure update on main thread
                self.friendsStories = [] 
            }
            return
        }
        
        print("Fetching stories for user IDs: \(idsToFetch)") // Log the IDs being fetched
        
        repository.fetchFriendsStories(userIds: idsToFetch) // Pass the potentially modified ID list
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .finished:
                    print("Successfully fetched friends stories for IDs: \(idsToFetch)")
                case .failure(let error):
                    print("Error fetching friends stories: \(error.localizedDescription)")
                    self.friendsStories = [] // Clear stories on error
                }
            } receiveValue: { [weak self] stories in
                guard let self = self else { return }
                self.friendsStories = stories
                print("Updated friends stories count: \(stories.count)")
            }
            .store(in: &cancellables)
    }
    
    // TODO: Add function to fetch user's own stories
    // TODO: Add function to potentially mark stories as viewed
}
