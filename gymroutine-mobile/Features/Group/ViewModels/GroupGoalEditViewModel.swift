import Foundation
import SwiftUI

@MainActor
class GroupGoalEditViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var targetValue: Double = 0
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Date()
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showSuccessAlert: Bool = false
    
    private let groupService = GroupService()
    
    var canUpdateGoal: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        targetValue > 0 &&
        endDate > startDate
    }
    
    var durationText: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        let days = components.day ?? 0
        return "\(days + 1)日間"
    }
    
    func initialize(with goal: GroupGoal) {
        title = goal.title
        description = goal.description ?? ""
        targetValue = goal.targetValue
        startDate = goal.startDate
        endDate = goal.endDate
    }
    
    func updateGoal(goalId: String, groupId: String) {
        Task {
            isLoading = true
            errorMessage = nil
            
            print("🔄 [GroupGoalEditViewModel] Starting goal update - goalId: \(goalId), groupId: \(groupId)")
            print("📊 [GroupGoalEditViewModel] Update data - title: '\(title)', targetValue: \(targetValue), endDate: \(endDate)")
            
            let result = await groupService.updateGroupGoal(
                goalId: goalId,
                groupId: groupId,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
                targetValue: targetValue,
                endDate: endDate
            )
            
            isLoading = false
            
            switch result {
            case .success(_):
                print("✅ [GroupGoalEditViewModel] Goal update successful, sending notification")
                showSuccessAlert = true
                // 목표 업데이트 성공 알림 발송
                NotificationCenter.default.post(name: AppConstants.NotificationNames.didUpdateGroupGoal, object: groupId)
                
            case .failure(let error):
                print("❌ [GroupGoalEditViewModel] Goal update failed: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
        }
    }
} 