import Foundation
import FirebaseFirestore

// MARK: - Group Model
struct GroupModel: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let description: String?
    let createdBy: String // User ID
    let createdAt: Date
    let updatedAt: Date
    var memberCount: Int
    var isPrivate: Bool
    // var imageUrl: String?
    var tags: [String] // 그룹 태그 (예: "근력", "유산소", "다이어트" 등)
    
    // Equatable conformance
    static func == (lhs: GroupModel, rhs: GroupModel) -> Bool {
        lhs.id == rhs.id // Primarily rely on ID for equality
    }
    
    // Placeholder for previews and navigation
    static var placeholder: GroupModel {
        GroupModel(id: "placeholder", 
                   name: "Loading Group...", 
                   description: "This is a placeholder group.", 
                   createdBy: "system", 
                   createdAt: Date(), 
                   updatedAt: Date(), 
                   memberCount: 0, 
                   isPrivate: false, 
                   tags: ["placeholder"])
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case createdBy = "createdBy"
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
        case memberCount = "memberCount"
        case isPrivate = "isPrivate"
        // case imageUrl = "imageUrl"
        case tags
    }
}

// MARK: - Group Member Model
struct GroupMember: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let userName: String
    let joinedAt: Date
    let role: GroupMemberRole
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "userId"
        case userName = "userName"
        case joinedAt = "joinedAt"
        case role
    }
}

enum GroupMemberRole: String, Codable, CaseIterable {
    case admin = "admin"     // 그룹 관리자
    case member = "member"   // メンバー // 일반 멤버
    
    var displayName: String {
        switch self {
        case .admin:
            return "管理者" // 管理者
        case .member:
            return "メンバー"
        }
    }
}

// MARK: - Group Goal Model
struct GroupGoal: Identifiable, Codable {
    @DocumentID var id: String?
    let title: String
    let description: String?
    let goalType: GroupGoalType
    let targetValue: Double // 목표 수치 (예: 운동 횟수, 시간 등)
    let unit: String // 단위 (예: "회", "분", "kg" 등)
    let startDate: Date
    let endDate: Date
    let createdBy: String // User ID
    let createdAt: Date
    var isActive: Bool
    var status: GroupGoalStatus? // 목표 상태 (기존 데이터 호환성을 위해 옵셔널)
    
    // 계산된 프로퍼티로 실제 상태 반환 (기본값: active)
    var actualStatus: GroupGoalStatus {
        return status ?? (isActive ? .active : .completed)
    }
    
    // 반복 관련 프로퍼티 추가
    let repeatType: String? // "none", "weekly", "monthly"
    let repeatCount: Int? // 반복 횟수
    let currentRepeatCycle: Int? // 현재 몇 번째 반복인지 (1부터 시작)
    
    // 진행률 계산을 위한 현재 달성값들
    var currentProgress: [String: Double] // userId: progress value
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case goalType = "goalType"
        case targetValue = "targetValue"
        case unit
        case startDate = "startDate"
        case endDate = "endDate"
        case createdBy = "createdBy"
        case createdAt = "createdAt"
        case isActive = "isActive"
        case status = "status"
        case repeatType = "repeatType"
        case repeatCount = "repeatCount" 
        case currentRepeatCycle = "currentRepeatCycle"
        case currentProgress = "currentProgress"
    }
}

enum GroupGoalType: String, Codable, CaseIterable {
    case workoutCount = "workoutCount"           // 운동 횟수
    case workoutDuration = "workoutDuration"     // 운동 시간
    case weightLifted = "weightLifted"           // 들어올린 총 무게
    // case caloriesBurned = "caloriesBurned"       // 소모 칼로리
    // case distanceRun = "distanceRun"             // 달린 거리
    // case stepCount = "stepCount"                 // 걸음 수
    
    var displayName: String {
        switch self {
        case .workoutCount:
            return "運動回数"
        case .workoutDuration:
            return "運動時間"
        case .weightLifted:
            return "トータル重量"
        // case .caloriesBurned:
        //     return "소모 칼로리"
        // case .distanceRun:
        //     return "달린 거리"
        // case .stepCount:
        //     return "걸음 수"
        }
    }
    
    var defaultUnit: String {
        switch self {
        case .workoutCount:
            return "回"
        case .workoutDuration:
            return "分"
        case .weightLifted:
            return "kg"
        // case .caloriesBurned:
        //     return "kcal"
        // case .distanceRun:
        //     return "km"
        // case .stepCount:
        //     return "걸음"
        }
    }
}

// 목표 상태 열거형 추가
enum GroupGoalStatus: String, Codable, CaseIterable {
    case active = "active"           // 진행 중
    case completed = "completed"     // 완료됨 (반복 완료 또는 기간 만료)
    case deleted = "deleted"         // 삭제됨 (사용자가 수동 삭제)
    case archived = "archived"       // 보관됨 (반복 갱신으로 인한 이전 주기)
    
    var displayName: String {
        switch self {
        case .active:
            return "進行中"
        case .completed:
            return "完了"
        case .deleted:
            return "削除済み"
        case .archived:
            return "保管済み"
        }
    }
    
    var displayColor: String {
        switch self {
        case .active:
            return "blue"
        case .completed:
            return "green"
        case .deleted:
            return "red"
        case .archived:
            return "gray"
        }
    }
}

// MARK: - Group Invitation Model
struct GroupInvitation: Identifiable, Codable {
    @DocumentID var id: String?
    let groupId: String
    let groupName: String
    let invitedBy: String // User ID who sent the invitation
    let invitedByName: String
    let invitedUser: String // User ID who is invited
    let invitedAt: Date
    var status: InvitationStatus
    var respondedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "groupId"
        case groupName = "groupName"
        case invitedBy = "invitedBy"
        case invitedByName = "invitedByName"
        case invitedUser = "invitedUser"
        case invitedAt = "invitedAt"
        case status
        case respondedAt = "respondedAt"
    }
}

enum InvitationStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .pending:
            return "待機中"
        case .accepted:
            return "承認済み"
        case .declined:
            return "拒否済み"
        case .expired:
            return "期限切れ"
        }
    }
}

// MARK: - Group Statistics Model
struct GroupStatistics: Codable {
    let groupId: String
    let totalWorkouts: Int
    let totalDuration: Double // minutes
    let totalWeight: Double // kg
    let averageWorkoutsPerMember: Double
    let topPerformers: [GroupMemberStats]
    let lastUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case groupId = "groupId"
        case totalWorkouts = "totalWorkouts"
        case totalDuration = "totalDuration"
        case totalWeight = "totalWeight"
        case averageWorkoutsPerMember = "averageWorkoutsPerMember"
        case topPerformers = "topPerformers"
        case lastUpdated = "lastUpdated"
    }
}

struct GroupMemberStats: Codable {
    let userId: String
    let userName: String
    let userProfileImageUrl: String?
    let workoutCount: Int
    let totalDuration: Double
    let totalWeight: Double
    let rank: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "userId"
        case userName = "userName"
        case userProfileImageUrl = "userProfileImageUrl"
        case workoutCount = "workoutCount"
        case totalDuration = "totalDuration"
        case totalWeight = "totalWeight"
        case rank
    }
} 