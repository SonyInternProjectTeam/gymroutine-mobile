import Foundation
import SwiftUI

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var groupInvitations: [GroupInvitation] = []
    @Published var otherNotifications: [GeneralNotification] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showSuccessAlert: Bool = false
    @Published var successMessage: String = ""
    
    private let groupService = GroupService()
    private let authService = AuthService()
    
    // 모든 알림을 통합해서 볼 수 있는 computed property
    var allNotifications: [Any] {
        var notifications: [Any] = []
        notifications.append(contentsOf: groupInvitations)
        notifications.append(contentsOf: otherNotifications)
        return notifications
    }
    
    // 읽지 않은 알림 개수
    var unreadNotificationsCount: Int {
        let unreadGroupInvitations = groupInvitations.count // 그룹 초대는 모두 읽지 않은 것으로 간주
        let unreadOtherNotifications = otherNotifications.filter { !$0.isRead }.count
        return unreadGroupInvitations + unreadOtherNotifications
    }
    
    /// 모든 알림을 로드
    func loadAllNotifications() {
        loadGroupInvitations()
        loadOtherNotifications()
    }
    
    /// 그룹 초대 목록을 로드
    private func loadGroupInvitations() {
        guard let currentUser = authService.getCurrentUser() else {
            errorMessage = "사용자가 로그인되어 있지 않습니다."
            return
        }
        
        Task {
            isLoading = true
            errorMessage = nil
            
            print("📧 [NotificationsViewModel] Loading group invitations for user: \(currentUser.uid)")
            
            let result = await groupService.getUserInvitations(userId: currentUser.uid)
            
            switch result {
            case .success(let invitations):
                self.groupInvitations = invitations
                print("✅ [NotificationsViewModel] Successfully loaded \(invitations.count) group invitations")
                
            case .failure(let error):
                print("⛔️ [NotificationsViewModel] Error loading group invitations: \(error)")
                errorMessage = error.localizedDescription
                groupInvitations = []
            }
            
            isLoading = false
        }
    }
    
    /// 기타 알림들을 로드 (향후 확장용)
    private func loadOtherNotifications() {
        // 향후 다른 알림 타입들 (팔로우 요청, 좋아요, 댓글 등)을 여기서 로드
        // 현재는 빈 배열로 설정
        otherNotifications = []
        
        // 예시: 향후 구현 예정
        // loadFollowRequests()
        // loadLikeNotifications()
        // loadCommentNotifications()
        // loadWorkoutNotifications()
    }
    
    /// 그룹 초대에 응답 (수락/거절)
    /// - Parameters:
    ///   - invitation: 응답할 초대
    ///   - accept: 수락 여부 (true: 수락, false: 거절)
    func respondToGroupInvitation(invitation: GroupInvitation, accept: Bool) {
        guard let invitationId = invitation.id else {
            errorMessage = "초대 ID가 올바르지 않습니다."
            return
        }
        
        Task {
            isLoading = true
            errorMessage = nil
            
            print("📧 [NotificationsViewModel] Responding to group invitation \(invitationId) with accept: \(accept)")
            
            let result = await groupService.respondToInvitation(invitationId: invitationId, accept: accept)
            
            isLoading = false
            
            switch result {
            case .success(_):
                // 로컬에서 해당 초대를 제거
                groupInvitations.removeAll { $0.id == invitationId }
                
                // 성공 메시지 표시
                if accept {
                    successMessage = "グループに参加しました！"
                    print("✅ [NotificationsViewModel] Successfully accepted group invitation: \(invitation.groupName)")
                } else {
                    successMessage = "招待を辞退しました"
                    print("✅ [NotificationsViewModel] Successfully declined group invitation: \(invitation.groupName)")
                }
                showSuccessAlert = true
                
            case .failure(let error):
                print("⛔️ [NotificationsViewModel] Error responding to group invitation: \(error)")
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - 향후 확장용 메서드들
    
    /// 팔로우 요청 알림 로드 (향후 구현)
    private func loadFollowRequests() {
        // 향후 구현 예정
    }
    
    /// 좋아요 알림 로드 (향후 구현)
    private func loadLikeNotifications() {
        // 향후 구현 예정
    }
    
    /// 댓글 알림 로드 (향후 구현)
    private func loadCommentNotifications() {
        // 향후 구현 예정
    }
    
    /// 운동 관련 알림 로드 (향후 구현)
    private func loadWorkoutNotifications() {
        // 향후 구현 예정
    }
    
    /// 알림을 읽음으로 표시 (향후 구현)
    func markAsRead(notificationId: String, type: NotificationType) {
        // 향후 구현 예정
    }
    
    /// 모든 알림을 읽음으로 표시 (향후 구현)
    func markAllAsRead() {
        // 향후 구현 예정
    }
} 