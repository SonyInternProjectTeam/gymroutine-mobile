import Foundation
import SwiftUI

@MainActor
final class GroupInviteViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var searchResults: [User] = []
    @Published var allUsers: [User] = []
    @Published var invitedUsers: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showSuccessAlert: Bool = false
    @Published var lastSearchedQuery: String = ""
    
    private let groupService = GroupService()
    private let userService = UserService()
    
    init() {
        loadAllUsers()
    }
    
    /// 특정 그룹의 초대 상태를 로드
    func loadInvitationStatuses(groupId: String) {
        Task {
            print("ℹ️ [GroupInviteViewModel] Attempting to load invitation statuses for groupId: \\(groupId)")
            let result = await groupService.getGroupInvitations(groupId: groupId)
            
            switch result {
            case .success(let invitations):
                // 대기 중인 초대 상태인 사용자들의 ID를 수집
                let pendingInviteUserIds = invitations
                    .filter { $0.status == .pending }
                    .map { $0.invitedUser }
                
                print("ℹ️ [GroupInviteViewModel] Received \\(invitations.count) invitations from service for group \\(groupId).")
                print("ℹ️ [GroupInviteViewModel] Filtered to \\(pendingInviteUserIds.count) pending invite user IDs for group \\(groupId).")

                let newInvitedUsers = Set(pendingInviteUserIds)
                if newInvitedUsers != invitedUsers {
                    invitedUsers = newInvitedUsers
                    print("✅ [GroupInviteViewModel] Updated invitedUsers for group \\(groupId). Count: \\(invitedUsers.count)")
                } else {
                    print("ℹ️ [GroupInviteViewModel] invitedUsers set remains unchanged for group \\(groupId). Count: \\(invitedUsers.count)")
                }
                
            case .failure(let error):
                print("⛔️ [GroupInviteViewModel] 초대 상태 로드 실패 for group \\(groupId): \\(error.localizedDescription)")
            }
        }
    }
    
    /// 모든 사용자를 로드 (초기 로드)
    private func loadAllUsers() {
        Task {
            isLoading = true
            errorMessage = nil
            
            let result = await userService.getAllUsers()
            
            isLoading = false
            
            switch result {
            case .success(let users):
                allUsers = users
                print("✅ [GroupInviteViewModel] 모든 사용자 로드 완료: \(users.count)명")
                
            case .failure(let error):
                print("⛔️ [GroupInviteViewModel] 사용자 로드 실패: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                allUsers = []
            }
        }
    }
    
    /// 프론트엔드에서 사용자 검색 (SnsView 참고)
    func searchUsers() {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            lastSearchedQuery = ""
            return
        }
        
        lastSearchedQuery = searchQuery
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // 프론트엔드에서 필터링
        let filteredUsers = allUsers.filter { user in
            // 사용자 이름으로 검색
            let nameMatch = user.name.lowercased().contains(trimmedQuery)
            
            // 사용자 이메일로 검색 (있는 경우)
            let emailMatch = user.email.lowercased().contains(trimmedQuery) ?? false
            
            return nameMatch || emailMatch
        }
        
        searchResults = filteredUsers
        print("✅ [GroupInviteViewModel] 검색 완료: '\(searchQuery)' -> \(filteredUsers.count)명 결과")
    }
    
    /// 사용자를 그룹에 초대
    func inviteUser(userId: String, groupId: String) {
        Task {
            isLoading = true
            errorMessage = nil
            
            let result = await groupService.inviteUserToGroup(groupId: groupId, userId: userId)
            
            isLoading = false
            
            switch result {
            case .success(_):
                invitedUsers.insert(userId)
                showSuccessAlert = true
                print("✅ [GroupInviteViewModel] 사용자 초대 성공: \\(userId)")
                
                // 초대 성공 알림 발송
                NotificationCenter.default.post(name: AppConstants.NotificationNames.groupMemberInvited, object: groupId)
                
            case .failure(let error):
                print("⛔️ [GroupInviteViewModel] 사용자 초대 실패: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
        }
    }
    
    /// 검색 결과 초기화
    func clearSearch() {
        searchResults = []
        lastSearchedQuery = ""
        errorMessage = nil
    }
    
    /// 사용자 목록 새로고침
    func refreshUsers(groupId: String) {
        loadAllUsers()
        loadInvitationStatuses(groupId: groupId)
    }
} 
