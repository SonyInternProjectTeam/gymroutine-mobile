//
//  SnsViewModel.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2025/04/01.
//

import Foundation
import SwiftUI
import FirebaseAuth

@MainActor
final class SnsViewModel: ObservableObject {
    @Published var userDetails: [User] = []       // User 型の配列に変更
    @Published var searchName: String = ""
    @Published var errorMessage: String? = nil
    
    // 推薦ユーザー関連の状態
    @Published var recommendedUsers: [RecommendedUser] = []
    @Published var isLoadingRecommendations: Bool = false
    @Published var recommendationsError: String? = nil
    
    // 추천 초기화 상태 (앱 실행 후 첫 번째 로드인지 확인)
    private var hasInitializedRecommendations = false
    
    private let userService = UserService()
    private let snsService = SnsService()
    private let authService = AuthService()
    
    /// ユーザー名でユーザー検索を行い、結果を userDetails に設定する
    func fetchUsers() {
        Task {
            UIApplication.showLoading()
            let result = await userService.searchUsersByName(name: searchName)
            switch result {
            case .success(let users):
                // 直接 User 型の配列を設定
                userDetails = users
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
            UIApplication.hideLoading()
        }
    }
    
    /// 現在のユーザーへのおすすめユーザーリストを取得する
    func fetchRecommendedUsers() {
        Task {
            guard let currentUser = authService.getCurrentUser() else {
                print("⛔️ [fetchRecommendedUsers] authService.getCurrentUser() returned nil")
                recommendationsError = "ユーザーがログインしていません"
                return
            }
            
            let userId = currentUser.uid
            print("✅ [fetchRecommendedUsers] 현재 유저 ID: \(userId)")
            
            isLoadingRecommendations = true
            recommendationsError = nil
            
            // 명시적으로 userId 파라미터 전달
            print("🔍 [fetchRecommendedUsers] 백엔드 API 호출 시작 - userId: \(userId)")
            let result = await snsService.getRecommendedUsers(for: userId)
            
            isLoadingRecommendations = false
            
            switch result {
            case .success(let users):
                print("✅ [fetchRecommendedUsers] 성공 - 추천 유저 \(users.count)명 가져옴")
                recommendedUsers = users.sorted(by: { $0.score > $1.score })
            case .failure(let error):
                print("⛔️ [fetchRecommendedUsers] 오류 발생: \(error.localizedDescription)")
                recommendationsError = "おすすめユーザーの取得に失敗しました: \(error.localizedDescription)"
            }
        }
    }
    
    /// 推薦リストを手動で更新する（ユーザーアクションでリフレッシュする場合）
    func refreshRecommendations() {
        Task {
            guard let currentUser = authService.getCurrentUser() else {
                print("⛔️ [refreshRecommendations] authService.getCurrentUser() returned nil")
                recommendationsError = "ユーザーがログインしていません"
                return
            }
            
            let userId = currentUser.uid
            print("✅ [refreshRecommendations] 현재 유저 ID: \(userId)")
            
            isLoadingRecommendations = true
            recommendationsError = nil
            
            // 명시적으로 userId 파라미터 전달
            print("🔍 [refreshRecommendations] 백엔드 API 호출 시작 - userId: \(userId)")
            let refreshResult = await snsService.refreshRecommendations(for: userId)
            
            switch refreshResult {
            case .success(let success):
                if success {
                    print("✅ [refreshRecommendations] 성공적으로 추천 목록 갱신")
                    // 更新に成功したら、新しい推薦リストを取得
                    print("🔍 [refreshRecommendations] 갱신된 추천 목록 요청 - userId: \(userId)")
                    let fetchResult = await snsService.getRecommendedUsers(for: userId)
                    
                    switch fetchResult {
                    case .success(let users):
                        print("✅ [refreshRecommendations] 성공 - 추천 유저 \(users.count)명 가져옴")
                        recommendedUsers = users.sorted(by: { $0.score > $1.score })
                    case .failure(let error):
                        print("⛔️ [refreshRecommendations] 추천 목록 조회 오류: \(error.localizedDescription)")
                        recommendationsError = "おすすめユーザーの取得に失敗しました: \(error.localizedDescription)"
                    }
                } else {
                    print("⛔️ [refreshRecommendations] 백엔드 API가 false 반환")
                    recommendationsError = "推薦リストの更新に失敗しました"
                }
            case .failure(let error):
                print("⛔️ [refreshRecommendations] 백엔드 API 오류: \(error.localizedDescription)")
                recommendationsError = "推薦リストの更新に失敗しました: \(error.localizedDescription)"
            }
            
            isLoadingRecommendations = false
        }
    }
    
    /// 추천 초기화 함수 - 페이지가 처음 열릴 때만 호출됨
    func initializeRecommendations() {
        // 이미 초기화했으면 일반 fetchRecommendedUsers만 호출
        if hasInitializedRecommendations {
            print("🔍 [SnsViewModel] 이미 초기화된 추천 - 데이터베이스에서 가져오기")
            fetchRecommendedUsers()
            return
        }
        
        // 처음 초기화하는 경우
        Task {
            guard let currentUser = authService.getCurrentUser() else {
                print("⛔️ [initializeRecommendations] authService.getCurrentUser() returned nil")
                recommendationsError = "ユーザーがログインしていません"
                return
            }
            
            let userId = currentUser.uid
            print("✅ [initializeRecommendations] 현재 유저 ID: \(userId)")
            
            isLoadingRecommendations = true
            recommendationsError = nil
            
            // 먼저 추천 목록이 있는지 확인
            print("🔍 [initializeRecommendations] 추천 목록 확인 - userId: \(userId)")
            let checkResult = await snsService.getRecommendedUsers(for: userId)
            
            switch checkResult {
            case .success(let users):
                // 추천 목록이 이미 있으면 바로 표시
                if !users.isEmpty {
                    print("✅ [initializeRecommendations] 기존 추천 목록 사용 - \(users.count)명")
                    recommendedUsers = users.sorted(by: { $0.score > $1.score })
                    hasInitializedRecommendations = true
                    isLoadingRecommendations = false
                    return
                }
                
                // 추천 목록이 없으면 생성
                print("🔍 [initializeRecommendations] 추천 목록 없음, 새로 생성 - userId: \(userId)")
                let refreshResult = await snsService.refreshRecommendations(for: userId)
                
                if case .failure(let error) = refreshResult {
                    print("⚠️ [initializeRecommendations] 추천 목록 생성 실패: \(error.localizedDescription)")
                    isLoadingRecommendations = false
                    recommendationsError = "おすすめユーザーの生成に失敗しました: \(error.localizedDescription)"
                    return
                }
                
                // 생성 후 다시 가져오기
                print("🔍 [initializeRecommendations] 생성된 추천 목록 가져오기")
                let result = await snsService.getRecommendedUsers(for: userId)
                
                switch result {
                case .success(let newUsers):
                    print("✅ [initializeRecommendations] 새 추천 목록 가져옴 - \(newUsers.count)명")
                    recommendedUsers = newUsers.sorted(by: { $0.score > $1.score })
                case .failure(let error):
                    print("⛔️ [initializeRecommendations] 추천 목록 가져오기 실패: \(error.localizedDescription)")
                    recommendationsError = "おすすめユーザーの取得に失敗しました: \(error.localizedDescription)"
                }
                
            case .failure(let error):
                // 추천 목록 확인 실패 - 새로 생성
                print("⚠️ [initializeRecommendations] 추천 목록 확인 실패, 새로 생성 시도: \(error.localizedDescription)")
                let refreshResult = await snsService.refreshRecommendations(for: userId)
                
                if case .success = refreshResult {
                    // 생성 성공 후 다시 가져오기
                    let result = await snsService.getRecommendedUsers(for: userId)
                    
                    switch result {
                    case .success(let newUsers):
                        print("✅ [initializeRecommendations] 새 추천 목록 가져옴 - \(newUsers.count)명")
                        recommendedUsers = newUsers.sorted(by: { $0.score > $1.score })
                    case .failure(let fetchError):
                        print("⛔️ [initializeRecommendations] 추천 목록 가져오기 실패: \(fetchError.localizedDescription)")
                        recommendationsError = "おすすめユーザーの取得に失敗しました: \(fetchError.localizedDescription)"
                    }
                } else {
                    print("⛔️ [initializeRecommendations] 추천 목록 생성 및 확인 모두 실패")
                    recommendationsError = "おすすめユーザーの取得に失敗しました: \(error.localizedDescription)"
                }
            }
            
            isLoadingRecommendations = false
            hasInitializedRecommendations = true
        }
    }
}
