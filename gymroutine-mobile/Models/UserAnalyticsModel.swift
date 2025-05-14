import Foundation
import FirebaseFirestore

// 부위별 운동 분포를 저장하는 딕셔너리 타입
typealias ExerciseDistribution = [String: Double]

// 1회 최대 중량 정보를 저장하는 딕셔너리 타입
typealias OneRepMaxInfo = [String: Double]

// 선호 운동 정보 구조체
struct FavoriteExercise: Codable, Hashable {
    let name: String        // 운동 이름
    let avgReps: Double     // 평균 반복 횟수
    let avgWeight: Double   // 평균 무게
}

// 팔로잉 비교 정보 구조체
struct FollowingComparison: Codable, Hashable {
    let user: Int           // 사용자 주간 운동 횟수
    let followingAvg: Int   // 팔로잉 사용자들의 평균 주간 운동 횟수
}

// 운동 준수율 구조체
struct WorkoutAdherence: Codable, Hashable {
    let thisWeek: Int       // 이번 주 준수율 (%)
    let thisMonth: Int      // 이번 달 준수율 (%)
}

// 사용자 운동 분석 데이터 모델
struct UserAnalytics: Codable, Identifiable {
    // Firestore 문서 ID (사용자 ID와 동일)
    @DocumentID var id: String?
    
    // 운동 부위별 분포 (예: "chest": 40, "back": 30 등)
    let distribution: ExerciseDistribution
    
    // 운동 준수율
    let adherence: WorkoutAdherence
    
    // 선호 운동 목록
    let favoriteExercises: [FavoriteExercise]
    
    // 팔로잉 사용자 대비 운동 빈도 비교
    let followingComparison: FollowingComparison
    
    // 1회 최대 중량 정보
    let oneRepMax: OneRepMaxInfo
    
    // 마지막 업데이트 시간
    let updatedAt: Timestamp
} 