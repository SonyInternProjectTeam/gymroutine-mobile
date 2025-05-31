import Foundation
import FirebaseFunctions
import FirebaseFirestore
import FirebaseAuth

class NotificationService {
    private let functions = Functions.functions(region: "asia-northeast1")
    private let db = Firestore.firestore()
    private let authService = AuthService()
    
    /// 사용자의 일반 알림 조회
    /// - Parameter userId: 사용자 ID
    /// - Returns: 알림 목록 또는 에러
    func getUserNotifications(userId: String) async -> Result<[GeneralNotification], Error> {
        do {
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
            print("⛔️ [NotificationService] Error getting user notifications: \(error)")
            return .failure(error)
        }
    }
    
    /// 알림을 읽음으로 표시 (클라이언트에서 직접 Firestore 업데이트)
    /// - Parameter notificationId: 알림 ID
    /// - Returns: 성공 여부
    func markNotificationAsRead(notificationId: String) async -> Result<Bool, Error> {
        guard let currentUser = authService.getCurrentUser() else {
            return .failure(NSError(domain: "NotificationService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자가 로그인되어 있지 않습니다."]))
        }
        
        do {
            let notificationRef = db.collection("Notifications").document(notificationId)
            
            // 먼저 알림이 존재하고 현재 사용자의 것인지 확인
            let notificationDoc = try await notificationRef.getDocument()
            
            guard notificationDoc.exists else {
                return .failure(NSError(domain: "NotificationService", code: 404, userInfo: [NSLocalizedDescriptionKey: "알림을 찾을 수 없습니다."]))
            }
            
            guard let notificationData = notificationDoc.data(),
                  let userId = notificationData["userId"] as? String,
                  userId == currentUser.uid else {
                return .failure(NSError(domain: "NotificationService", code: 403, userInfo: [NSLocalizedDescriptionKey: "접근 권한이 없습니다."]))
            }
            
            // 읽음 처리
            try await notificationRef.updateData([
                "isRead": true,
                "readAt": Timestamp(date: Date())
            ])
            
            print("✅ [NotificationService] Successfully marked notification as read: \(notificationId)")
            return .success(true)
            
        } catch {
            print("⛔️ [NotificationService] Error marking notification as read: \(error)")
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
} 