import Foundation
import SwiftUI
import FirebaseFunctions
import FirebaseFirestore // Import for Timestamp


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
    private let notificationService = NotificationService()
    
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
    
    /// 기타 알림들을 로드
    private func loadOtherNotifications() {
        guard let currentUser = authService.getCurrentUser() else {
            return
        }
        
        Task {
            print("📧 [NotificationsViewModel] Loading general notifications for user: \(currentUser.uid)")
            
            let result = await notificationService.getUserNotifications(userId: currentUser.uid)
            
            switch result {
            case .success(let notifications):
                self.otherNotifications = notifications
                print("✅ [NotificationsViewModel] Successfully loaded \(notifications.count) general notifications")
                
            case .failure(let error):
                print("⛔️ [NotificationsViewModel] Error loading general notifications: \(error)")
                // Don't set errorMessage here as it might overwrite group invitation errors
                otherNotifications = []
            }
        }
    }
    
    /// 일반 알림 조회 (백엔드 API 사용)
    private func loadGeneralNotifications(userId: String) async -> Result<[GeneralNotification], Error> {
        do {
            let functions = Functions.functions(region: "asia-northeast1")
            let result = try await functions.httpsCallable("getUserNotifications").call()
            
            if let resultData = result.data as? [String: Any],
               let notificationsData = resultData["notifications"] as? [[String: Any]] {
                
                let notifications = try notificationsData.compactMap { notificationData -> GeneralNotification? in
                    guard let id = notificationData["id"] as? String,
                          let title = notificationData["title"] as? String,
                          let message = notificationData["message"] as? String,
                          let type = notificationData["type"] as? String,
                          let isRead = notificationData["isRead"] as? Bool else {
                        return nil
                    }
                    
                    let createdAt: Date
                    if let timestamp = notificationData["createdAt"] as? Timestamp {
                        createdAt = timestamp.dateValue()
                    } else if let dateDouble = notificationData["createdAt"] as? Double {
                        createdAt = Date(timeIntervalSince1970: dateDouble / 1000)
                    } else {
                        createdAt = Date()
                    }
                    
                    // 타입에 따른 아이콘과 색상 설정
                    let (iconName, iconColor) = getIconAndColor(for: type)
                    
                    return GeneralNotification(
                        id: id,
                        title: title,
                        message: message,
                        iconName: iconName,
                        iconColor: iconColor,
                        createdAt: createdAt,
                        isRead: isRead,
                        type: NotificationType(rawValue: type) ?? .achievement
                    )
                }
                
                return .success(notifications)
            } else {
                return .failure(NSError(domain: "NotificationService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"]))
            }
        } catch {
            return .failure(error)
        }
    }
    
    /// 알림 타입에 따른 아이콘과 색상 반환
    private func getIconAndColor(for type: String) -> (iconName: String, iconColor: String) {
        switch type {
        case "new_follower":
            return ("person.badge.plus", "blue")
        case "group_goal_created":
            return ("target", "green")
        case "follow_request":
            return ("person.crop.circle.badge.questionmark", "orange")
        case "like":
            return ("heart.fill", "red")
        case "comment":
            return ("bubble.left", "blue")
        case "workout":
            return ("figure.run", "purple")
        default:
            return ("bell", "gray")
        }
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
    
    /// 알림을 읽음으로 표시
    /// - Parameter notificationId: 알림 ID
    func markNotificationAsRead(notificationId: String) {
        // 먼저 로컬에서 즉시 업데이트 (UI 반응성 향상)
        if let index = otherNotifications.firstIndex(where: { $0.id == notificationId }) {
            let notification = otherNotifications[index]
            if !notification.isRead {
                otherNotifications[index] = GeneralNotification(
                    id: notification.id,
                    title: notification.title,
                    message: notification.message,
                    iconName: notification.iconName,
                    iconColor: notification.iconColor,
                    createdAt: notification.createdAt,
                    isRead: true,
                    type: notification.type
                )
                
                // 백그라운드에서 서버 업데이트
                Task {
                    let result = await notificationService.markNotificationAsRead(notificationId: notificationId)
                    
                    switch result {
                    case .success(_):
                        print("✅ [NotificationsViewModel] Successfully marked notification as read: \(notificationId)")
                        
                    case .failure(let error):
                        print("⛔️ [NotificationsViewModel] Error marking notification as read: \(error)")
                        // 실패 시 로컬 상태를 다시 되돌림
                        if let index = self.otherNotifications.firstIndex(where: { $0.id == notificationId }) {
                            self.otherNotifications[index] = GeneralNotification(
                                id: notification.id,
                                title: notification.title,
                                message: notification.message,
                                iconName: notification.iconName,
                                iconColor: notification.iconColor,
                                createdAt: notification.createdAt,
                                isRead: false,
                                type: notification.type
                            )
                        }
                    }
                }
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
    
    /// 모든 알림을 읽음으로 표시
    func markAllAsRead() {
        let unreadNotifications = otherNotifications.filter { !$0.isRead }
        
        if unreadNotifications.isEmpty {
            return
        }
        
        // 먼저 로컬에서 모든 알림을 읽음으로 표시 (UI 반응성 향상)
        for (index, notification) in otherNotifications.enumerated() {
            if !notification.isRead {
                otherNotifications[index] = GeneralNotification(
                    id: notification.id,
                    title: notification.title,
                    message: notification.message,
                    iconName: notification.iconName,
                    iconColor: notification.iconColor,
                    createdAt: notification.createdAt,
                    isRead: true,
                    type: notification.type
                )
            }
        }
        
        // 백그라운드에서 서버 업데이트
        Task {
            var failedUpdates: [GeneralNotification] = []
            
            for notification in unreadNotifications {
                let result = await notificationService.markNotificationAsRead(notificationId: notification.id)
                
                switch result {
                case .success(_):
                    print("✅ [NotificationsViewModel] Successfully marked notification as read: \(notification.id)")
                    
                case .failure(let error):
                    print("⛔️ [NotificationsViewModel] Error marking notification as read: \(error)")
                    failedUpdates.append(notification)
                }
            }
            
            // 실패한 업데이트가 있으면 해당 알림들을 다시 읽지 않음으로 되돌림
            if !failedUpdates.isEmpty {
                for failedNotification in failedUpdates {
                    if let index = self.otherNotifications.firstIndex(where: { $0.id == failedNotification.id }) {
                        self.otherNotifications[index] = GeneralNotification(
                            id: failedNotification.id,
                            title: failedNotification.title,
                            message: failedNotification.message,
                            iconName: failedNotification.iconName,
                            iconColor: failedNotification.iconColor,
                            createdAt: failedNotification.createdAt,
                            isRead: false,
                            type: failedNotification.type
                        )
                    }
                }
                print("⚠️ [NotificationsViewModel] Failed to mark \(failedUpdates.count) notifications as read")
            } else {
                print("✅ [NotificationsViewModel] Successfully marked all \(unreadNotifications.count) notifications as read")
            }
        }
    }
} 