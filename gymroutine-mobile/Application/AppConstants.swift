import Foundation

struct AppConstants {
    struct NotificationNames {
        static let didCreateGroupGoal = Notification.Name("didCreateGroupGoalNotification")
        static let didUpdateGroupGoal = Notification.Name("didUpdateGroupGoalNotification")
        static let groupMemberInvited = Notification.Name("GroupMemberInvitedNotification") // Standardized string here
        static let didJoinGroup = Notification.Name("didJoinGroupNotification")
    }

    // Other global constants can go here
} 