//
//  HomeViewModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/03/01.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var followingUsers: [User] = []
    @Published var todaysWorkouts: [Workout] = []  // 오늘의 워크아웃 목록 추가
    @Published var activeStoriesByUserID: [String: [Story]] = [:] // [UserID: [Story]] dictionary to store active stories
    @Published var selectedUserForStory: User? = nil // For triggering navigation
    @Published var storiesForSelectedUser: [Story] = [] // Stories to pass to StoryView
    
    private let snsService = SnsService()
    private let workoutRepository = WorkoutRepository()  // Repository 인스턴스 추가
    private let storyService = StoryService.shared // Add StoryService instance
    private var cancellables = Set<AnyCancellable>() // Add cancellables
    
    init() {
        setupSubscribers()
        loadFollowingUsers()
        loadTodaysWorkouts()
    }
    
    deinit {
        // ViewModel이 해제될 때 실시간 업데이트 중지
        storyService.stopRealtimeUpdates()
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
    
    /// 현재 사용자가 팔로우 중인 사용자 목록 불러오기 & 스토리 가져오기 트리거
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
                // 기존 일회성 로드 대신 실시간 업데이트 시작
                storyService.startRealtimeUpdates(userId: currentUserID)
            case .failure(let error):
                print("팔로잉ユーザーの読み込みに失敗しました: \(error.localizedDescription)")
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
    
    // 실시간 업데이트 수동 새로고침
    func refreshStories() {
        guard let currentUserID = UserManager.shared.currentUser?.uid else { return }
        storyService.startRealtimeUpdates(userId: currentUserID)
    }
    
    /// WorkoutRepository에서 워크아웃을 불러와 오늘의 워크아웃만 필터링
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
                // scheduledDays 배열에 오늘의 요일이 포함된 워크아웃만 필터링
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
    
    /// 오늘의 요일을 문자열로 반환 (예: "Monday")
    private func getTodayWeekdayString() -> String {
        let dateFormatter = DateFormatter()
        // locale 및 dateFormat은 워크아웃 도큐먼트에 저장된 요일 형식에 맞게 조정 필요
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "EEEE" // ex) "Monday", "Tuesday", ...
        return dateFormatter.string(from: Date())
    }
}
