import Foundation
import SwiftUI

// 반복 옵션 enum 추가
enum RepeatOption: String, CaseIterable {
    case none = "none"
    case weekly = "weekly" 
    case monthly = "monthly"
    
    var displayName: String {
        switch self {
        case .none:
            return "反復なし"
        case .weekly:
            return "毎週"
        case .monthly:
            return "毎月"
        }
    }
    
    var iconName: String {
        switch self {
        case .none:
            return "calendar"
        case .weekly:
            return "calendar.badge.clock"
        case .monthly:
            return "calendar.badge.plus"
        }
    }
}

@MainActor
class GroupGoalCreateViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var selectedGoalType: GroupGoalType = .workoutCount
    @Published var targetValue: Double = 0
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Date()
    
    // 반복 기능 관련 프로퍼티 추가
    @Published var selectedRepeatOption: RepeatOption = .none {
        didSet {
            updateEndDateForRepeat()
        }
    }
    @Published var repeatCount: Int = 1 { // 반복 횟수 (몇 주/몇 개월)
        didSet {
            updateEndDateForRepeat()
        }
    }
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showSuccessAlert: Bool = false
    
    private let groupService = GroupService()
    
    var canCreateGoal: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        targetValue > 0 &&
        endDate > startDate &&
        !isGoalTypeUnderDevelopment
    }
    
    // 개발중인 목표 유형인지 확인
    var isGoalTypeUnderDevelopment: Bool {
        selectedGoalType == .workoutDuration || selectedGoalType == .weightLifted
    }
    
    var durationText: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        let days = components.day ?? 0
        
        if selectedRepeatOption != .none && repeatCount > 1 {
            return "\(days + 1)日間 × \(repeatCount)\(selectedRepeatOption == .weekly ? "週" : "月")"
        } else {
            return "\(days + 1)日間"
        }
    }
    
    // 반복 설정에 따라 실제 종료일을 계산
    var actualEndDate: Date {
        let calendar = Calendar.current
        let baseDuration = calendar.dateComponents([.day], from: startDate, to: endDate)
        
        switch selectedRepeatOption {
        case .none:
            return endDate
        case .weekly:
            let totalWeeks = repeatCount
            let daysToAdd = (totalWeeks * 7) - 7 + (baseDuration.day ?? 0)
            return calendar.date(byAdding: .day, value: daysToAdd, to: startDate) ?? endDate
        case .monthly:
            let totalMonths = repeatCount
            let baseEndDate = calendar.date(byAdding: .month, value: totalMonths - 1, to: endDate) ?? endDate
            return baseEndDate
        }
    }
    
    func initializeDates() {
        let calendar = Calendar.current
        startDate = calendar.startOfDay(for: Date())
        let weekLater = calendar.date(byAdding: .day, value: 7, to: startDate) ?? startDate
        // 23:59:59로 설정
        endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: weekLater) ?? weekLater
    }
    
    // 반복 옵션 변경 시 종료일 자동 조정
    func updateEndDateForRepeat() {
        guard selectedRepeatOption != .none else { return }
        
        let calendar = Calendar.current
        switch selectedRepeatOption {
        case .none:
            break
        case .weekly:
            // 주간 반복: 7일 단위로 설정 (23:59:59)
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: startDate) ?? startDate
            endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: weekEnd) ?? weekEnd
        case .monthly:
            // 월간 반복: 1개월 단위로 설정 (23:59:59)
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
            let lastDayOfMonth = calendar.date(byAdding: .day, value: -1, to: monthEnd) ?? monthEnd
            endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: lastDayOfMonth) ?? lastDayOfMonth
        }
    }
    
    func createGoal(groupId: String) {
        Task {
            isLoading = true
            errorMessage = nil
            
            print("🔄 [GroupGoalCreateViewModel] Starting goal creation - groupId: \(groupId)")
            print("📊 [GroupGoalCreateViewModel] Goal data - title: '\(title)', type: \(selectedGoalType.rawValue), targetValue: \(targetValue), endDate: \(endDate)")
            
            let result = await groupService.createGroupGoalWithNotifications(
                groupId: groupId,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
                goalType: selectedGoalType.rawValue,
                targetValue: targetValue,
                startDate: startDate,
                endDate: endDate,
                repeatType: selectedRepeatOption.rawValue,
                repeatCount: selectedRepeatOption != .none ? repeatCount : nil
            )
            
            isLoading = false
            
            switch result {
            case .success(_):
                print("✅ [GroupGoalCreateViewModel] Goal creation successful, sending notification")
                showSuccessAlert = true
                // 목표 생성 성공 알림 발송
                NotificationCenter.default.post(name: AppConstants.NotificationNames.didCreateGroupGoal, object: groupId)
                
            case .failure(let error):
                print("❌ [GroupGoalCreateViewModel] Goal creation failed: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
        }
    }
} 