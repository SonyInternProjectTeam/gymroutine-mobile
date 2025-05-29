import Foundation
import SwiftUI
import Combine

@MainActor
final class GroupEditViewModel: ObservableObject {
    @Published var groupName: String = ""
    @Published var groupDescription: String = ""
    @Published var isPrivate: Bool = false
    @Published var tags: [String] = []
    @Published var newTag: String = ""
    @Published var members: [GroupMember] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMembers: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showDeleteAlert: Bool = false
    @Published var showInviteSheet: Bool = false
    @Published var hasChanges: Bool = false
    @Published var showRemoveMemberAlert: Bool = false
    @Published var memberToRemove: GroupMember? = nil
    
    private var originalGroup: GroupModel?
    private let groupService = GroupService()
    
    func initialize(with group: GroupModel) {
        originalGroup = group
        groupName = group.name
        groupDescription = group.description ?? ""
        isPrivate = group.isPrivate
        tags = group.tags
        
        // 멤버 로드
        if let groupId = group.id {
            loadMembers(groupId: groupId)
        }
        
        // 변경사항 감지 설정
        setupChangeDetection()
    }
    
    private func setupChangeDetection() {
        // 변경사항을 감지하여 hasChanges 업데이트
        $groupName
            .combineLatest($groupDescription, $isPrivate, $tags)
            .map { [weak self] name, description, isPrivate, tags in
                guard let self = self, let original = self.originalGroup else { return false }
                
                return name != original.name ||
                       description != (original.description ?? "") ||
                       isPrivate != original.isPrivate ||
                       tags != original.tags
            }
            .assign(to: &$hasChanges)
    }
    
    func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty && !tags.contains(trimmedTag) else { return }
        
        tags.append(trimmedTag)
        newTag = ""
    }
    
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    func updateGroup() {
        guard let originalGroup = originalGroup,
              let groupId = originalGroup.id else { return }
        
        Task {
            isLoading = true
            errorMessage = nil
            
            let updatedGroup = GroupModel(
                id: groupId,
                name: groupName,
                description: groupDescription.isEmpty ? nil : groupDescription,
                createdBy: originalGroup.createdBy,
                createdAt: originalGroup.createdAt,
                updatedAt: Date(),
                memberCount: originalGroup.memberCount,
                isPrivate: isPrivate,
                tags: tags
            )
            
            let result = await groupService.updateGroup(updatedGroup)
            
            isLoading = false
            
            switch result {
            case .success(_):
                // 성공적으로 업데이트됨
                self.originalGroup = updatedGroup
                hasChanges = false
                showSuccessAlert = true
                
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    @Published var showSuccessAlert: Bool = false
    @Published var isGroupDeleted: Bool = false
    
    func deleteGroup() {
        guard let groupId = originalGroup?.id else { return }
        
        Task {
            isLoading = true
            errorMessage = nil
            
            let result = await groupService.deleteGroup(groupId: groupId)
            
            isLoading = false
            
            switch result {
            case .success(_):
                isGroupDeleted = true
                showSuccessAlert = true
                
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func removeMember(_ member: GroupMember) {
        self.memberToRemove = member
        self.showRemoveMemberAlert = true
    }
    
    func confirmRemoveMember() {
        guard let member = memberToRemove, let groupId = originalGroup?.id else {
            errorMessage = "削除するメンバー情報が見つからないか、グループIDがありません。" // Member info to delete not found or no Group ID
            memberToRemove = nil // Clear the stored member
            return
        }
        
        Task {
            isLoading = true // Or a more specific isLoadingMembers if preferred
            errorMessage = nil
            
            print("ℹ️ [GroupEditViewModel] Confirming removal of member \(member.userId) from group \(groupId)")
            
            let result = await groupService.removeUserFromGroup(userId: member.userId, groupId: groupId)
            
            isLoading = false
            memberToRemove = nil // Clear the stored member after operation
            
            switch result {
            case .success:
                print("✅ [GroupEditViewModel] Successfully removed member \(member.userId). Refreshing member list.")
                // Local list will be updated by loadMembers
                loadMembers(groupId: groupId)
                // Optionally, show a brief success message if needed, though list refresh might be enough
                
            case .failure(let error):
                print("⛔️ [GroupEditViewModel] Error removing member \(member.userId): \(error.localizedDescription)")
                errorMessage = "メンバーの削除に失敗しました: \(error.localizedDescription)" // Failed to remove member
            }
        }
    }
    
    private func loadMembers(groupId: String) {
        Task {
            isLoadingMembers = true
            
            let result = await groupService.getGroupMembers(groupId: groupId)
            
            isLoadingMembers = false
            
            switch result {
            case .success(let members):
                self.members = members
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
} 