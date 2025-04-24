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
    
    init() {
        setupSubscribers()
        loadFollowingUsers()
        loadTodaysWorkouts()
        loadHeatmapData() // Load heatmap data
        setupAppLifecycleObservers()
        setupHeatmapRealTimeListener()
    }
    
    deinit {
        // Stop realtime updates when ViewModel is deallocated
        storyService.stopRealtimeUpdates()
        heatmapListener?.remove() // Remove Firestore listener
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
    }
    
    @objc private func refreshDataOnAppActive() {
        print("App became active, refreshing data...")
        loadHeatmapData() // Refresh heatmap data
    }
    
    @objc private func refreshHeatmapOnWorkoutComplete() {
        print("Workout completed, refreshing heatmap...")
        loadHeatmapData() // Refresh heatmap when a workout is completed
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
    }
    
    /// Group fetched stories by user ID
    private func groupStoriesByUser(_ stories: [Story]) {
        activeStoriesByUserID = Dictionary(grouping: stories, by: { $0.userId })
        print("Updated active stories: \(activeStoriesByUserID.count) users have stories.")
    }
    
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
                storyService.startRealtimeUpdates(userId: currentUserID)
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
                let todayString = Date().weekdayString()
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
}
