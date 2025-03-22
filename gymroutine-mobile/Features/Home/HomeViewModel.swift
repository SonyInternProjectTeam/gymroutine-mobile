//
//  HomeViewModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/03/01.
//

import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var followingUsers: [User] = []
    @Published var todaysWorkouts: [Workout] = []  // 오늘의 워크아웃 목록 추가
    
    private let snsService = SnsService()
    private let workoutRepository = WorkoutRepository()  // Repository 인스턴스 추가
    
    init() {
        loadFollowingUsers()
        loadTodaysWorkouts()
    }
    
    /// 현재 사용자가 팔로우 중인 사용자 목록 불러오기
    func loadFollowingUsers() {
        Task {
            UIApplication.showLoading()
            guard let currentUserID = UserManager.shared.currentUser?.uid else { return }
            let result = await snsService.getFollowingUsers(for: currentUserID)
            switch result {
            case .success(let users):
                self.followingUsers = users
            case .failure(let error):
                print("팔로잉ユーザーの読み込みに失敗しました: \(error.localizedDescription)")
            }
            UIApplication.hideLoading()
        }
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
