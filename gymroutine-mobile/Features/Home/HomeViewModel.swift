//
//  HomeViewModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/03/01.
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var followingUsers: [User] = []
    @Published var activeFollowingUsers: [User] = [] // isActive true인 친구들
    @Published var todaysWorkouts: [Workout] = []  // Today's workouts list
    @Published var activeStoriesByUserID: [String: [Story]] = [:] // [UserID: [Story]] dictionary to store active stories
    @Published var selectedUserForStory: User? = nil // For triggering navigation
    @Published var storiesForSelectedUser: [Story] = [] // Stories to pass to StoryView
    @Published var heatmapData: [Date: Int] = [:] // Heatmap data
    
    private let snsService = SnsService()
    private let workoutRepository = WorkoutRepository()  // Repository instance
    private let storyService = StoryService.shared // Add StoryService instance
    private let heatmapService = HeatmapService() // Heatmap service
    private var cancellables = Set<AnyCancellable>() // Add cancellables
    private var heatmapListener: ListenerRegistration? // Firestore listener for heatmap updates
    private var activeUsersListener: ListenerRegistration? // 활성 유저 리스너
    private var activeUsersRetryCount = 0 // 활성 유저 리스너 재시도 횟수
    private let maxActiveUsersRetryCount = 3 // 최대 재시도 횟수
    
    init() {
        setupSubscribers()
        loadFollowingUsers()
        loadTodaysWorkouts()
        loadHeatmapData() // Load heatmap data
        setupAppLifecycleObservers()
        setupHeatmapRealTimeListener()
        setupActiveUsersRealTimeListener() // 활성 유저 실시간 감지 설정
    }
    
    deinit {
        // Stop realtime updates when ViewModel is deallocated
        storyService.stopRealtimeUpdates()
        heatmapListener?.remove() // Remove Firestore listener
        activeUsersListener?.remove() // 활성 유저 리스너 제거
        NotificationCenter.default.removeObserver(self)
    }
    
    // Setup app lifecycle observers to refresh data when app becomes active
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshDataOnAppActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Also listen for workout completion notifications if available
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshHeatmapOnWorkoutComplete),
            name: NSNotification.Name("WorkoutCompletedNotification"),
            object: nil
        )
        
        // 백그라운드에서 포그라운드로 전환될 때 활성 유저 상태 확인
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkActiveUsersOnAppActive),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func refreshDataOnAppActive() {
        print("App became active, refreshing data...")
        loadHeatmapData() // Refresh heatmap data
    }
    
    @objc private func refreshHeatmapOnWorkoutComplete() {
        print("Workout completed, refreshing heatmap...")
        loadHeatmapData() // Refresh heatmap when a workout is completed
    }
    
    @objc private func checkActiveUsersOnAppActive() {
        print("App will enter foreground, checking active users...")
        forceCheckActiveUsers() // Force refresh active users when app becomes active
    }
    
    // Setup a real-time listener for the current month's heatmap data
    private func setupHeatmapRealTimeListener() {
        guard let currentUserID = UserManager.shared.currentUser?.uid else { return }
        
        // Get current month in YYYYMM format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMM"
        let currentMonth = dateFormatter.string(from: Date())
        
        // Create reference to the heatmap document
        let db = Firestore.firestore()
        let heatmapRef = db.collection("WorkoutHeatmap")
            .document(currentUserID)
            .collection(currentMonth)
            .document("heatmapData")
        
        // Add real-time listener
        heatmapListener = heatmapRef.addSnapshotListener { [weak self] (documentSnapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error listening for heatmap updates: \(error.localizedDescription)")
                return
            }
            
            guard let document = documentSnapshot, document.exists else {
                print("Heatmap document does not exist or was deleted")
                return
            }
            
            // Process the document data and update heatmapData
            if let data = document.data(), let heatmapDict = data["heatmapData"] as? [String: Int] {
                print("Real-time update received for heatmap data")
                Task {
                    // Convert string dates to Date objects
                    var newHeatmapData: [Date: Int] = [:]
                    let dayFormatter = DateFormatter()
                    dayFormatter.dateFormat = "yyyy-MM-dd"
                    
                    for (dateString, count) in heatmapDict {
                        if let date = dayFormatter.date(from: dateString) {
                            let calendar = Calendar.current
                            if let normalizedDate = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: date)) {
                                newHeatmapData[normalizedDate] = count
                            }
                        }
                    }
                    
                    // Update the published property on the main thread
                    await MainActor.run {
                        self.heatmapData = newHeatmapData
                        print("Updated heatmap data with \(newHeatmapData.count) entries from real-time update")
                    }
                }
            }
        }
    }
    
    private func setupSubscribers() {
        // Subscribe to StoryService's friendsStories updates
        storyService.$friendsStories
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stories in
                self?.groupStoriesByUser(stories)
            }
            .store(in: &cancellables)
        
        // Subscribe to AppWorkoutManager's isWorkoutSessionActive updates for better syncing
        AppWorkoutManager.shared.$isWorkoutSessionActive
            .dropFirst() // Skip initial value (false)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                if !isActive {
                    // Workout session ended, check active users after a short delay
                    // to allow Firestore to update
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self?.forceCheckActiveUsers()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    /// Group fetched stories by user ID
    private func groupStoriesByUser(_ stories: [Story]) {
        activeStoriesByUserID = Dictionary(grouping: stories, by: { $0.userId })
        print("Updated active stories: \(activeStoriesByUserID.count) users have stories.")
    }
    
    /// Load following users and trigger story fetching
    func loadFollowingUsers() {
        Task {
            UIApplication.showLoading()
            guard let currentUserID = UserManager.shared.currentUser?.uid else { 
                UIApplication.hideLoading()
                return 
            }
            let result = await snsService.getFollowingUsers(for: currentUserID)
            switch result {
            case .success(let users):
                self.followingUsers = users
                // Start realtime updates instead of one-time load
                storyService.startRealtimeUpdates(userId: currentUserID)
                // Re-setup active users listener with new following list
                setupActiveUsersRealTimeListener()
            case .failure(let error):
                print("Failed to load following users: \(error.localizedDescription)")
            }
            UIApplication.hideLoading()
        }
    }
    
    // Function to check if a user has active stories
    func userHasActiveStory(userId: String) -> Bool {
        let hasStory = activeStoriesByUserID[userId]?.isEmpty == false
        // print("DEBUG: userHasActiveStory for \(userId): \(hasStory)") // Uncomment for debugging
        return hasStory
    }
    
    // Function to prepare and trigger story view navigation
    func showStories(for user: User) {
        print("DEBUG: Attempting to show stories for user: \(user.name) (ID: \(user.uid))") // Log attempt
        if let stories = activeStoriesByUserID[user.uid], !stories.isEmpty {
            print("DEBUG: Found \(stories.count) active stories for user \(user.name).") // Log story count
            self.storiesForSelectedUser = stories.sorted { $0.createdAt.dateValue() < $1.createdAt.dateValue() } // Sort stories chronologically
            self.selectedUserForStory = user // This should trigger the .sheet
            print("DEBUG: Set selectedUserForStory to \(user.name). Sheet should present.") // Log state change
        } else {
            print("DEBUG: No active stories found for user \(user.name) in activeStoriesByUserID.") // Log if no stories found
            self.storiesForSelectedUser = []
            self.selectedUserForStory = nil
        }
    }
    
    // Manual refresh for realtime updates
    func refreshStories() {
        guard let currentUserID = UserManager.shared.currentUser?.uid else { return }
        storyService.startRealtimeUpdates(userId: currentUserID)
    }
    
    // Global refresh method for all data
    func refreshAllData() {
        loadFollowingUsers()
        loadTodaysWorkouts()
        loadHeatmapData()
        refreshStories()
        forceCheckActiveUsers()
    }
    
    /// Load workouts from WorkoutRepository and filter for today's workouts
    func loadTodaysWorkouts() {
        guard let currentUserID = UserManager.shared.currentUser?.uid else {
            print("DEBUG: current user is nil, cannot load today's workouts")
            return
        }
        Task {
            UIApplication.showLoading()
            do {
                let workouts = try await workoutRepository.fetchWorkouts(for: currentUserID)
                let todayString = getTodayWeekdayString()
                // Filter workouts that include today's weekday in their scheduledDays array
                let filteredWorkouts = workouts.filter { $0.scheduledDays.contains(todayString) }
                DispatchQueue.main.async {
                    self.todaysWorkouts = filteredWorkouts
                }
                print("DEBUG: Loaded \(filteredWorkouts.count) today's workouts for user \(currentUserID)")
            } catch {
                print("DEBUG: Failed to load today's workouts: \(error)")
            }
            UIApplication.hideLoading()
        }
    }
    
    /// Load heatmap data for the current user
    func loadHeatmapData() {
        guard let currentUserID = UserManager.shared.currentUser?.uid else {
            print("DEBUG: current user is nil, cannot load heatmap data")
            return
        }
        
        Task {
            UIApplication.showLoading()
            
            // Load data through HeatmapService
            let data = await heatmapService.getMonthlyHeatmapData(for: currentUserID)
            
            // Update UI on the main thread
            await MainActor.run {
                self.heatmapData = data
                print("DEBUG: Loaded \(data.count) heatmap entries")
                UIApplication.hideLoading()
            }
        }
    }
    
    /// Load heatmap data for a specific year and month (used when changing months)
    func loadHeatmapData(for year: Int, month: Int) {
        guard let currentUserID = UserManager.shared.currentUser?.uid else {
            print("DEBUG: current user is nil, cannot load heatmap data")
            return
        }
        
        Task {
            UIApplication.showLoading()
            
            // Load data for specific month through HeatmapService
            let data = await heatmapService.getHeatmapData(for: currentUserID, year: year, month: month)
            
            await MainActor.run {
                self.heatmapData = data
                print("DEBUG: Loaded \(data.count) heatmap entries for \(year)/\(month)")
                UIApplication.hideLoading()
            }
        }
    }
    
    /// Returns today's weekday as a string (e.g., "Monday")
    private func getTodayWeekdayString() -> String {
        let dateFormatter = DateFormatter()
        // locale and dateFormat should match the format stored in workout documents
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "EEEE" // ex) "Monday", "Tuesday", ...
        return dateFormatter.string(from: Date())
    }
    
    // 활동 중인 유저를 실시간으로 감지하는 리스너 설정
    func setupActiveUsersRealTimeListener() {
        guard let currentUserID = UserManager.shared.currentUser?.uid else { 
            print("🔴 활성 유저 리스너 설정 실패: 현재 사용자 ID가 없음")
            return 
        }
        
        // 이미 리스너가 있으면 제거
        activeUsersListener?.remove()
        activeUsersListener = nil
        
        print("🔄 활성 유저 리스너 설정 시작 - 현재 사용자: \(currentUserID)")
        
        // 팔로우하는 모든 사용자 목록 확인
        // 빈 목록이면 팔로잉 목록을 먼저 가져온 후 설정
        if followingUsers.isEmpty {
            print("⚠️ 팔로우 목록이 비어있음, 팔로잉 유저 목록 먼저 로드")
            Task {
                await loadFollowingUsersAndSetupActiveUsersListener(for: currentUserID)
            }
            return
        }
        
        // 이미 팔로잉 목록이 있으면 바로 리스너 설정
        setupActiveUsersListenerWithFollowingList(currentUserID: currentUserID)
    }
    
    // 팔로잉 목록을 가져온 후 활성 유저 리스너 설정
    private func loadFollowingUsersAndSetupActiveUsersListener(for currentUserID: String) async {
        let result = await snsService.getFollowingUsers(for: currentUserID)
        
        switch result {
        case .success(let users):
            self.followingUsers = users
            print("✅ 팔로잉 목록 로드 성공 - \(users.count)명")
            
            // 팔로잉 목록으로 활성 유저 리스너 설정
            setupActiveUsersListenerWithFollowingList(currentUserID: currentUserID)
            
        case .failure(let error):
            print("🔴 팔로잉 목록 로드 실패: \(error.localizedDescription)")
            // 재시도 로직 구현 (필요시)
            activeUsersRetryCount += 1
            if activeUsersRetryCount < maxActiveUsersRetryCount {
                print("⚠️ 활성 유저 리스너 설정 재시도 (\(activeUsersRetryCount)/\(maxActiveUsersRetryCount))")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    Task { [weak self] in
                        await self?.loadFollowingUsersAndSetupActiveUsersListener(for: currentUserID)
                    }
                }
            } else {
                print("🔴 최대 재시도 횟수 초과, 활성 유저 리스너 설정 실패")
                activeUsersRetryCount = 0
            }
        }
    }
    
    // 팔로잉 목록으로 활성 유저 리스너 설정
    private func setupActiveUsersListenerWithFollowingList(currentUserID: String) {
        // 팔로잉 유저 ID 리스트 추출
        let followingUserIDs = followingUsers.map { $0.uid }
        
        // 현재 사용자 ID도 추가 (자신의 활성 상태도 확인)
        var allUserIDs = followingUserIDs
        if !allUserIDs.contains(currentUserID) {
            allUserIDs.append(currentUserID)
        }
        
        // 빈 배열이면 리스너 설정 생략
        if allUserIDs.isEmpty {
            print("⚠️ 팔로우하는 유저가 없어 활성 유저 리스너 설정 건너뜀")
            return
        }
        
        print("🔍 활성 유저 감지 대상: \(allUserIDs.count)명")
        
        // Firestore 배치 크기 제한(10명)을 고려한 배치 처리
        setupActiveUsersListenerInBatches(userIDs: allUserIDs)
    }
    
    // Firestore 배치 크기 제한(in 연산자 max 10)을 고려한 리스너 설정
    private func setupActiveUsersListenerInBatches(userIDs: [String]) {
        let db = Firestore.firestore()
        let batchSize = 10 // Firestore 'in' 연산자 최대 개수
        
        // 기존 리스너 제거
        activeUsersListener?.remove()
        activeUsersListener = nil
        
        // 배치 크기 이하면 단일 쿼리로 처리
        if userIDs.count <= batchSize {
            activeUsersListener = db.collection("Users")
                .whereField("uid", in: userIDs)
                .whereField("isActive", isEqualTo: true)
                .addSnapshotListener { [weak self] snapshot, error in
                    self?.handleActiveUsersSnapshot(snapshot: snapshot, error: error)
                }
            return
        }
        
        // 배치 크기 초과 시 멀티 쿼리 사용 (첫 배치만 리스너로 설정)
        print("⚠️ 팔로우 사용자가 \(userIDs.count)명으로 배치 크기(\(batchSize))를 초과합니다.")
        print("⚠️ 첫 \(batchSize)명에 대해서만 실시간 리스너를 설정하고, 나머지는 주기적으로 갱신합니다.")
        
        // 첫 배치에만 실시간 리스너 설정
        let firstBatch = Array(userIDs.prefix(batchSize))
        activeUsersListener = db.collection("Users")
            .whereField("uid", in: firstBatch)
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                self?.handleActiveUsersSnapshot(snapshot: snapshot, error: error)
            }
        
        // 나머지 배치는 주기적 폴링 구현 (필요시)
        // 여기서는 실시간 업데이트에 집중하므로 생략하지만, 필요시 30초마다 폴링하는 코드 추가 가능
    }
    
    // 활성 유저 스냅샷 처리 공통 함수
    private func handleActiveUsersSnapshot(snapshot: QuerySnapshot?, error: Error?) {
        if let error = error {
            print("🔴 활성 유저 감지 오류: \(error.localizedDescription)")
            return
        }
        
        guard let documents = snapshot?.documents else {
            print("⚠️ 활성 유저 문서 없음")
            self.activeFollowingUsers = []
            return
        }
        
        do {
            // User 객체로 변환
            let activeUsers = try documents.compactMap { document -> User? in
                try document.data(as: User.self)
            }
            
            print("✅ 활성 유저 감지: \(activeUsers.count)명")
            
            // UI 업데이트
            DispatchQueue.main.async {
                self.activeFollowingUsers = activeUsers
            }
        } catch {
            print("🔴 활성 유저 데이터 변환 오류: \(error.localizedDescription)")
            self.activeFollowingUsers = []
        }
    }
    
    // 활동 중인 유저를 강제로 확인 (앱 전환, 홈 화면 새로고침 등에서 사용)
    func forceCheckActiveUsers() {
        print("🔄 활성 사용자 강제 확인 시작")
        
        // 기존 리스너 제거 후 다시 설정 (완전히 새로운 데이터 가져오기)
        activeUsersListener?.remove()
        activeUsersListener = nil
        activeUsersRetryCount = 0 // 재시도 카운트 초기화
        
        // 활성 유저 리스너 재설정
        setupActiveUsersRealTimeListener()
    }
    
    // 모든 홈 데이터 새로고침
    func refreshHomeData() {
        print("🔄 홈 데이터 새로고침 시작")
        
        // 활성 유저 상태 확인
        forceCheckActiveUsers()
        
        // 기존 코드 그대로 유지
        Task {
            await loadFollowingUsers()
            await loadTodaysWorkouts()
            await loadHeatmapData()
        }
    }
}
