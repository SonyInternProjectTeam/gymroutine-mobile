import Foundation
import SwiftUI
import Combine

// Struct for displaying pending members
struct PendingMemberDisplay: Identifiable, Hashable {
    let id: String // User ID (from User.uid)
    let name: String
    let profilePhotoUrl: String?
    let invitationDate: Date
}

@MainActor
class GroupDetailViewModel: ObservableObject {
    @Published var selectedTab: GroupDetailTab = .members
    @Published var members: [GroupMember] = []
    @Published var goals: [GroupGoal] = []
    @Published var statistics: GroupStatistics? = nil
    @Published var pendingMembers: [PendingMemberDisplay] = [] // New property for pending members
    
    @Published var isLoadingMembers: Bool = false
    @Published var isLoadingGoals: Bool = false
    @Published var isLoadingStats: Bool = false
    @Published var isLoadingPendingMembers: Bool = false // New loading state
    
    private let groupService = GroupService()
    private let authService = AuthService()
    
    private var currentGroupId: String? // For notification handling
    private var cancellables = Set<AnyCancellable>() // For Notification observers or Combine
    private var isNewlyJoined: Bool = false // Hint for loading data after a fresh join
    
    /// 현재 사용자가 그룹 관리자인지 확인
    var isCurrentUserAdmin: Bool {
        guard let currentUser = authService.getCurrentUser() else { return false }
        return members.first { $0.userId == currentUser.uid }?.role == .admin
    }
    
    func loadGroupData(groupId: String, isNewlyJoined: Bool = false) {
        self.currentGroupId = groupId
        self.isNewlyJoined = isNewlyJoined // Store the hint
        registerForNotifications()

        Task {
            if self.isNewlyJoined {
                // If newly joined, wait a bit for Firestore to hopefully catch up.
                // You might want to make this delay configurable or use a more robust retry.
                print("ℹ️ [GroupDetailViewModel] Newly joined, adding a small delay before loading data for group \(groupId).")
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                self.isNewlyJoined = false // Reset hint after first use
            }
            // Now proceed with loading all data
            await fetchAllGroupData(groupId: groupId)
        }
    }
    
    private func fetchAllGroupData(groupId: String) async {
        // Using a TaskGroup to load members, goals, stats, and pending invitations concurrently
        isLoadingMembers = true // Set combined loading states if needed, or handle individually
        isLoadingGoals = true
        isLoadingStats = true
        isLoadingPendingMembers = true

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadMembers(groupId: groupId) }
            group.addTask { await self.loadGoals(groupId: groupId) }
            group.addTask { await self.loadStatistics(groupId: groupId) }
            group.addTask { await self.loadPendingInvitations(groupId: groupId) }
        }
        
        // Reset loading states after all tasks are done
        // Note: Individual load functions already set their specific isLoading to false.
        // This is more of a conceptual reset if you had a global "isLoadingAllData" flag.
        // Since they are separate, this might not be strictly needed here.
        print("✅ [GroupDetailViewModel] All initial data loaded for group \(groupId).")
    }
    
    private func loadMembers(groupId: String) async {
        isLoadingMembers = true
        
        let result = await groupService.getGroupMembers(groupId: groupId)
        
        isLoadingMembers = false
        
        switch result {
        case .success(let members):
            self.members = members
        case .failure(let error):
            print("Error loading members: \(error)")
        }
    }
    
    private func loadGoals(groupId: String) async {
        isLoadingGoals = true
        print("🎯 [GroupDetailViewModel] Loading goals for group: \(groupId)")
        
        let result = await groupService.getGroupGoals(groupId: groupId)
        
        isLoadingGoals = false
        
        switch result {
        case .success(let goals):
            self.goals = goals
            print("✅ [GroupDetailViewModel] Successfully loaded \(goals.count) goals for group: \(groupId)")
        case .failure(let error):
            print("⛔️ [GroupDetailViewModel] Error loading goals: \(error)")
        }
    }
    
    private func loadStatistics(groupId: String) async {
        isLoadingStats = true
        
        let result = await groupService.getGroupStatistics(groupId: groupId)
        
        isLoadingStats = false
        
        switch result {
        case .success(let stats):
            self.statistics = stats
        case .failure(let error):
            print("Error loading statistics: \(error)")
        }
    }
    
    // New function to load pending invitations
    private func loadPendingInvitations(groupId: String) async {
        isLoadingPendingMembers = true
        self.pendingMembers = [] // Clear previous results

        print("ℹ️ [GroupDetailViewModel] Loading pending invitations for group \(groupId)")
        let invitationResult = await groupService.getGroupInvitations(groupId: groupId)
        
        switch invitationResult {
        case .success(let invitations):
            let pendingInvites = invitations.filter { $0.status == .pending }
            print("ℹ️ [GroupDetailViewModel] Found \\(pendingInvites.count) pending invitations for group \\(groupId).")

            if pendingInvites.isEmpty {
                isLoadingPendingMembers = false
                return
            }
            
            var fetchedPendingMembers: [PendingMemberDisplay] = []
            
            await withTaskGroup(of: PendingMemberDisplay?.self) { taskGroup in
                for invite in pendingInvites {
                    taskGroup.addTask {
                        print("ℹ️ [GroupDetailViewModel] Fetching user details for pending invite: \\(invite.invitedUser)")
                        let userResult = await UserService.shared.getUser(userId: invite.invitedUser)
                        switch userResult {
                        case .success(let user):
                            print("✅ [GroupDetailViewModel] Successfully fetched user \\(user.name) for pending invite.")
                            return PendingMemberDisplay(
                                id: user.uid,
                                name: user.name,
                                profilePhotoUrl: user.profilePhoto.isEmpty ? nil : user.profilePhoto,
                                invitationDate: invite.invitedAt
                            )
                        case .failure(let error):
                            print("⛔️ [GroupDetailViewModel] Error fetching user \\(invite.invitedUser) for pending invite: \\(error.localizedDescription)")
                            return nil
                        }
                    }
                }
                
                for await memberDisplayResult in taskGroup {
                    if let member = memberDisplayResult {
                        fetchedPendingMembers.append(member)
                    }
                }
            }
            
            self.pendingMembers = fetchedPendingMembers.sorted(by: { $0.invitationDate > $1.invitationDate })
            print("✅ [GroupDetailViewModel] Loaded \\(self.pendingMembers.count) pending members for group \\(groupId).")
            
        case .failure(let error):
            print("⛔️ [GroupDetailViewModel] Error loading all pending invitations for group \\(groupId): \\(error.localizedDescription)")
        }
        isLoadingPendingMembers = false
    }

    func refreshGoals(groupId: String) async {
        await loadGoals(groupId: groupId)
    }
    
    func updateUserGoalProgress(goalId: String, newProgress: Double, groupId: String) async {
        guard let userId = authService.getCurrentUser()?.uid else {
            print("⛔️ [GroupDetailViewModel] User not logged in. Cannot update progress.")
            return
        }

        print("ℹ️ [GroupDetailViewModel] Attempting to update progress for goal \(goalId) to \(newProgress) by user \(userId)")
        
        let result = await groupService.updateGoalProgress(goalId: goalId, groupId: groupId, progress: newProgress)
        
        switch result {
        case .success(let data):
            print("✅ [GroupDetailViewModel] Successfully updated progress for goal \(goalId): \(data)")
            
            // 로컬 데이터 즉시 업데이트 (UX 향상)
            if let index = self.goals.firstIndex(where: { $0.id == goalId }) {
                self.goals[index].currentProgress[userId] = newProgress
                
                // 목표가 완료되었는지 확인
                if let goalCompleted = data["goalCompleted"] as? Bool, goalCompleted {
                    self.goals[index].status = .completed
                    self.goals[index].isActive = false
                    print("🎉 [GroupDetailViewModel] Goal \(goalId) completed by all members!")
                }
                
                self.objectWillChange.send()
            }
            
            // 서버에서 최신 데이터 가져오기 (목표 완료 상태 동기화)
            await self.loadGoals(groupId: groupId)

        case .failure(let error):
            print("⛔️ [GroupDetailViewModel] Failed to update progress for goal \(goalId): \(error.localizedDescription)")
        }
    }
    
    func deleteGoal(goalId: String, groupId: String) async {
        print("🗑️ [GroupDetailViewModel] Attempting to delete goal \(goalId) from group \(groupId)")
        let result = await groupService.deleteGroupGoal(goalId: goalId, groupId: groupId)
        
        switch result {
        case .success(_):
            print("✅ [GroupDetailViewModel] Successfully deleted goal \(goalId). Updating local data.")
            // 로컬 데이터에서 삭제된 목표 제거
            self.goals.removeAll { $0.id == goalId }
            
        case .failure(let error):
            print("⛔️ [GroupDetailViewModel] Failed to delete goal \(goalId): \(error.localizedDescription)")
            // 에러 처리 (선택사항: UI에 에러 메시지 표시)
        }
    }
    
    // MARK: - Testing Functions
    
    /// 반복 목표 수동 갱신 (테스팅용)
    /// - Parameter groupId: 그룹 ID (갱신 후 목표를 새로고침하기 위해)
    func manualRenewRepeatingGoals(groupId: String) {
        Task {
            print("🔄 [GroupDetailViewModel] Starting manual renewal of repeating goals")
            let result = await groupService.manualRenewRepeatingGoals()
            
            switch result {
            case .success(let data):
                print("✅ [GroupDetailViewModel] Manual renewal completed: \(data)")
                Task { await loadGoals(groupId: groupId) }
                
            case .failure(let error):
                print("⛔️ [GroupDetailViewModel] Manual renewal failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// 목표 완료 상태 확인 (모든 멤버가 달성했는지 확인)
    /// - Parameter groupId: 그룹 ID
    func checkGoalCompletion(groupId: String) {
        Task {
            print("🔄 [GroupDetailViewModel] Checking goal completion for group: \(groupId)")
            let result = await groupService.checkGoalCompletion(groupId: groupId)
            
            switch result {
            case .success(let data):
                print("✅ [GroupDetailViewModel] Goal completion check completed: \(data)")
                
                if let completedCount = data["completedGoalsCount"] as? Int, completedCount > 0 {
                    print("🎉 [GroupDetailViewModel] \(completedCount) goals auto-completed!")
                    Task { await loadGoals(groupId: groupId) }
                }
                
            case .failure(let error):
                print("⛔️ [GroupDetailViewModel] Goal completion check failed: \(error.localizedDescription)")
            }
        }
    }
    
    // Notification handling for goal creation (will be added fully in the next step)
    private func registerForNotifications() {
        NotificationCenter.default.removeObserver(self, name: AppConstants.NotificationNames.didCreateGroupGoal, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleGoalCreation(notification:)), name: AppConstants.NotificationNames.didCreateGroupGoal, object: nil)
        
        // Add observer for goal updates
        NotificationCenter.default.removeObserver(self, name: AppConstants.NotificationNames.didUpdateGroupGoal, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleGoalUpdate(notification:)), name: AppConstants.NotificationNames.didUpdateGroupGoal, object: nil)
        
        // Add observer for when a member is invited (from GroupInviteViewModel)
        NotificationCenter.default.removeObserver(self, name: AppConstants.NotificationNames.groupMemberInvited, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleMemberInvited(notification:)), name: AppConstants.NotificationNames.groupMemberInvited, object: nil)
    }

    @objc private func handleGoalCreation(notification: Notification) {
        if let notifiedGroupId = notification.object as? String, notifiedGroupId == self.currentGroupId {
            print("ℹ️ [GroupDetailViewModel] Received .didCreateGroupGoal notification. Refreshing goals for group \(notifiedGroupId).")
            Task { await refreshGoals(groupId: notifiedGroupId) }
        } else if notification.object == nil, let currentGroupId = self.currentGroupId {
            print("ℹ️ [GroupDetailViewModel] Received .didCreateGroupGoal notification (no specific groupID). Refreshing goals for current group \(currentGroupId).")
            Task { await refreshGoals(groupId: currentGroupId) }
        }
    }
    
    @objc private func handleGoalUpdate(notification: Notification) {
        if let notifiedGroupId = notification.object as? String, notifiedGroupId == self.currentGroupId {
            print("ℹ️ [GroupDetailViewModel] Received .didUpdateGroupGoal notification. Refreshing goals for group \(notifiedGroupId).")
            Task { await refreshGoals(groupId: notifiedGroupId) }
        } else if notification.object == nil, let currentGroupId = self.currentGroupId {
            print("ℹ️ [GroupDetailViewModel] Received .didUpdateGroupGoal notification (no specific groupID). Refreshing goals for current group \(currentGroupId).")
            Task { await refreshGoals(groupId: currentGroupId) }
        }
    }
    
    @objc private func handleMemberInvited(notification: Notification) {
        if let notifiedGroupId = notification.object as? String, notifiedGroupId == self.currentGroupId {
            print("ℹ️ [GroupDetailViewModel] Received GroupMemberInvited notification. Refreshing pending members for group \\(notifiedGroupId).")
            Task { await loadPendingInvitations(groupId: notifiedGroupId) }
        } else if notification.object == nil, let currentGroupId = self.currentGroupId {
             print("ℹ️ [GroupDetailViewModel] Received GroupMemberInvited notification (no specific groupID). Refreshing pending members for current group \\(currentGroupId).")
            Task { await loadPendingInvitations(groupId: currentGroupId) }
        }
    }
    
    // It's good practice to remove observers, e.g., in a deinit or a specific cleanup method.
    // For @StateObject VMs tied to View lifecycle, this might be less critical but still good form.
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("ℹ️ [GroupDetailViewModel] Deinitialized and removed observers.")
    }
}

// Definition for Notification.Name.didCreateGroupGoal (will be added to a shared location later)
// extension Notification.Name {
// static let didCreateGroupGoal = Notification.Name("didCreateGroupGoalNotification")
// }

enum GroupDetailTab: CaseIterable {
    case members, goals, stats
    
    var title: String {
        switch self {
        case .members: return "メンバー"
        case .goals: return "目標"
        case .stats: return "統計"
        }
    }
    
    var iconName: String {
        switch self {
        case .members: return "person.2"
        case .goals: return "target"
        case .stats: return "chart.bar"
        }
    }
} 