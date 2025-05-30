import Foundation
import SwiftUI

@MainActor
final class GroupSearchViewModel: ObservableObject {
    @Published var searchResults: [GroupModel] = []
    @Published var allGroups: [GroupModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var availableTags: [String] = []
    @Published var selectedTags: [String] = []
    @Published var lastSearchedQuery: String = ""
    @Published var joinedGroupIds: Set<String> = []
    @Published var myGroupIds: Set<String> = []
    @Published var isJoiningGroup: Bool = false
    @Published var successfullyJoinedGroup: GroupModel? = nil
    
    private let groupService = GroupService()
    private let authService = AuthService()
    private var currentUserId: String? { authService.getCurrentUser()?.uid }
    
    init() {
        loadAvailableTags()
        loadAllPublicGroups()
        fetchMyGroupIds()
    }
    
    /// 모든 공개 그룹을 로드 (초기 로드)
    func loadAllPublicGroups() {
        Task {
            isLoading = true
            errorMessage = nil
            
            let result = await groupService.getAllPublicGroups()
            
            isLoading = false
            
            switch result {
            case .success(let groups):
                allGroups = groups
                print("✅ [GroupSearchViewModel] 모든 공개 그룹 로드 완료: \(groups.count)개")
                
            case .failure(let error):
                print("⛔️ [GroupSearchViewModel] 공개 그룹 로드 실패: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                allGroups = []
            }
        }
    }
    
    /// 프론트엔드에서 그룹 검색 (SnsView 참고)
    func searchGroups(query: String) {
        lastSearchedQuery = query
        
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // 프론트엔드에서 필터링
        var filteredGroups = allGroups.filter { group in
            // 그룹 이름으로 검색
            let nameMatch = group.name.lowercased().contains(trimmedQuery)
            
            // 그룹 설명으로 검색
            let descriptionMatch = group.description?.lowercased().contains(trimmedQuery) ?? false
            
            // 태그로 검색
            let tagMatch = group.tags.contains { tag in
                tag.lowercased().contains(trimmedQuery)
            }
            
            return nameMatch || descriptionMatch || tagMatch
        }
        
        // 선택된 태그로 추가 필터링
        if !selectedTags.isEmpty {
            filteredGroups = filteredGroups.filter { group in
                selectedTags.allSatisfy { selectedTag in
                    group.tags.contains(selectedTag)
                }
            }
        }
        
        searchResults = filteredGroups
        print("✅ [GroupSearchViewModel] 검색 완료: '\(query)' -> \(filteredGroups.count)개 결과")
    }
    
    /// 검색 결과 초기화
    func clearSearch() {
        searchResults = []
        lastSearchedQuery = ""
        errorMessage = nil
    }
    
    /// 태그 토글
    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.removeAll { $0 == tag }
        } else {
            selectedTags.append(tag)
        }
    }
    
    /// 사용 가능한 태그 로드
    func loadAvailableTags() {
        // 일반적인 운동 관련 태그들
        availableTags = [
            // "근력운동", "유산소", "다이어트", "벌크업", "헬스", "홈트레이닝",
            // "요가", "필라테스", "러닝", "사이클링", "수영", "크로스핏"
        ]
    }
    
    /// 그룹 목록 새로고침
    func refreshGroups() {
        loadAllPublicGroups()
    }
    
    /// 사용자가 속한 그룹 ID 목록을 가져옴
    func fetchMyGroupIds() {
        guard let userId = currentUserId else {
            // 사용자가 로그인하지 않은 경우 처리 (선택 사항)
            print("ℹ️ [GroupSearchViewModel] User not logged in, cannot fetch their groups.")
            return
        }
        
        Task {
            // isLoading 상태를 별도로 관리하거나, 기존 isLoading을 활용할 수 있습니다.
            // 여기서는 별도 상태 없이 진행합니다.
            let result = await groupService.getUserGroups(userId: userId) // Assuming getUserGroups returns groups user is in
            switch result {
            case .success(let groups):
                self.myGroupIds = Set(groups.compactMap { $0.id })
                print("✅ [GroupSearchViewModel] 사용자의 그룹 ID 목록 로드 완료: \(self.myGroupIds.count)개")
            case .failure(let error):
                print("⛔️ [GroupSearchViewModel] 사용자 그룹 ID 목록 로드 실패: \(error.localizedDescription)")
                // 에러 메시지 표시 등 필요한 처리
            }
        }
    }

    /// 공개 그룹에 가입
    func joinPublicGroup(group: GroupModel) {
        guard let groupId = group.id, !group.isPrivate else {
            errorMessage = "비공개 그룹이거나 그룹 ID가 없습니다."
            return
        }
        guard let userId = currentUserId else {
            errorMessage = "로그인이 필요합니다."
            return
        }

        // 이미 가입했거나, 현재 세션에서 가입 요청한 그룹인지 확인
        if myGroupIds.contains(groupId) || joinedGroupIds.contains(groupId) {
            print("ℹ️ [GroupSearchViewModel] 이미 가입했거나 가입 요청 중인 그룹입니다: \(groupId)")
            // 이미 가입된 경우 사용자에게 알림 (선택 사항)
            // self.errorMessage = "이미 가입된 그룹입니다."
            return
        }
        
        Task {
            isJoiningGroup = true
            errorMessage = nil
            
            let result = await groupService.joinPublicGroup(groupId: groupId, userId: userId)
            
            isJoiningGroup = false
            
            switch result {
            case .success:
                print("✅ [GroupSearchViewModel] 그룹 가입 성공: \(groupId)")
                joinedGroupIds.insert(groupId)
                myGroupIds.insert(groupId) // 사용자의 그룹 목록에도 추가하여 상태 일관성 유지
                // 성공 메시지 또는 UI 업데이트 트리거 (예: joinedGroupIds 변경으로 View가 업데이트됨)
                // 검색 결과 목록에서 해당 그룹의 상태를 업데이트해야 할 수도 있음 (예: isJoined 플래그)
                if let index = searchResults.firstIndex(where: { $0.id == groupId }) {
                    searchResults[index].memberCount += 1 // Optimistic update
                    // searchResults[index].isJoined = true (if you add such a property to GroupModel or a wrapper)
                }
                if let indexAll = allGroups.firstIndex(where: { $0.id == groupId }) {
                    allGroups[indexAll].memberCount += 1
                }
                // Navigate after successful join
                self.successfullyJoinedGroup = group
                
                // Send notification that user joined a group
                NotificationCenter.default.post(name: AppConstants.NotificationNames.didJoinGroup, object: groupId)

            case .failure(let error):
                print("⛔️ [GroupSearchViewModel] 그룹 가입 실패: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
        }
    }
} 