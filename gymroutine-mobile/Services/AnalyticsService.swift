//
//  AnalyticsService.swift
//  gymroutine-mobile
//

import Foundation
import FirebaseAnalytics

class AnalyticsService {
    static let shared = AnalyticsService()
    
    private init() {
        // Firebase Analytics는 자동으로 초기화됩니다
        print("Firebase Analytics 서비스 초기화됨")
    }
    
    // MARK: - 기본 이벤트 로깅
    
    /// Firebase Analytics에 이벤트 로그
    /// - Parameters:
    ///   - name: 이벤트 이름 (Firebase에서 지원하는 이름 또는 커스텀 이름)
    ///   - parameters: 이벤트 파라미터 (옵션)
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }
    
    // MARK: - 일반적인 이벤트
    
    /// 화면 조회 이벤트 로깅
    /// - Parameter screenName: 화면 이름
    func logScreenView(screenName: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenName + "View"
        ])
    }
    
    /// 회원가입 이벤트 로깅
    /// - Parameters:
    ///   - method: 회원가입 방식 (예: "email", "google", "apple" 등)
    ///   - success: 회원가입 성공 여부
    func logSignUp(method: String, success: Bool) {
        Analytics.logEvent(AnalyticsEventSignUp, parameters: [
            AnalyticsParameterMethod: method,
            "success": success
        ])
    }
    
    /// 로그인 이벤트 로깅
    /// - Parameters:
    ///   - method: 로그인 방식 (예: "email", "google", "apple" 등)
    ///   - success: 로그인 성공 여부
    func logLogin(method: String, success: Bool) {
        Analytics.logEvent(AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method,
            "success": success
        ])
    }
    
    /// 사용자 액션 이벤트 로깅
    /// - Parameters:
    ///   - action: 수행된 액션 (예: "button_tap", "swipe", 등)
    ///   - itemId: 관련 항목 ID (옵션)
    ///   - itemName: 관련 항목 이름 (옵션)
    ///   - contentType: 콘텐츠 유형 (옵션)
    func logUserAction(action: String, itemId: String? = nil, itemName: String? = nil, contentType: String? = nil) {
        var parameters: [String: Any] = [
            "action": action
        ]
        
        if let itemId = itemId {
            parameters["item_id"] = itemId
        }
        
        if let itemName = itemName {
            parameters["item_name"] = itemName
        }
        
        if let contentType = contentType {
            parameters["content_type"] = contentType
        }
        
        Analytics.logEvent("user_action", parameters: parameters)
    }
    
    // MARK: - 워크아웃 관련 이벤트
    
    /// 워크아웃 시작 이벤트 로깅
    func logWorkoutStarted(workoutId: String, workoutName: String, isRoutine: Bool, exerciseCount: Int) {
        Analytics.logEvent("workout_started", parameters: [
            "workout_id": workoutId,
            "workout_name": workoutName,
            "is_routine": isRoutine,
            "exercise_count": exerciseCount,
            "start_time": Date().timeIntervalSince1970
        ])
    }
    
    /// 워크아웃 완료 이벤트 로깅
    func logWorkoutCompleted(workoutId: String, workoutName: String, duration: TimeInterval, completedExercises: Int) {
        Analytics.logEvent("workout_completed", parameters: [
            "workout_id": workoutId,
            "workout_name": workoutName,
            "duration_seconds": duration,
            "completed_exercises": completedExercises
        ])
    }
    
    /// 운동 완료 이벤트 로깅
    func logExerciseCompleted(exerciseName: String, workoutId: String, sets: Int, reps: Int, weight: Double?) {
        var params: [String: Any] = [
            "exercise_name": exerciseName,
            "workout_id": workoutId,
            "sets_completed": sets,
            "total_reps": reps
        ]
        
        if let weight = weight {
            params["weight_kg"] = weight
        }
        
        Analytics.logEvent("exercise_completed", parameters: params)
    }
    
    // MARK: - 소셜 관련 이벤트
    
    /// 스토리 조회 이벤트 로깅
    func logStoryViewed(storyId: String, authorId: String, viewDuration: TimeInterval) {
        Analytics.logEvent("story_viewed", parameters: [
            "story_id": storyId,
            "author_id": authorId,
            "view_duration_seconds": viewDuration
        ])
    }
    
    /// 사용자 팔로우 이벤트 로깅
    func logUserFollowed(followedUserId: String, fromScreen: String) {
        Analytics.logEvent("user_followed", parameters: [
            "followed_user_id": followedUserId,
            "from_screen": fromScreen
        ])
    }
    
    /// 사용자 언팔로우 이벤트 로깅
    func logUserUnfollowed(unfollowedUserId: String, fromScreen: String) {
        Analytics.logEvent("user_unfollowed", parameters: [
            "unfollowed_user_id": unfollowedUserId,
            "from_screen": fromScreen
        ])
    }
    
    /// 소셜 콘텐츠 공유 이벤트 로깅
    func logContentShared(contentType: String, contentId: String, shareMethod: String) {
        Analytics.logEvent("content_shared", parameters: [
            "content_type": contentType,
            "content_id": contentId,
            "share_method": shareMethod
        ])
    }
    
    // MARK: - 분석 관련 이벤트
    
    /// 분석 데이터 조회 이벤트 로깅
    func logAnalyticsViewed(analyticsType: String, timePeriod: String) {
        Analytics.logEvent("analytics_viewed", parameters: [
            "analytics_type": analyticsType,
            "time_period": timePeriod
        ])
    }
    
    /// 목표 설정 이벤트 로깅
    func logGoalSet(goalType: String, targetValue: Double, timeFrame: String) {
        Analytics.logEvent("goal_set", parameters: [
            "goal_type": goalType,
            "target_value": targetValue,
            "time_frame": timeFrame
        ])
    }
    
    /// 목표 달성 이벤트 로깅
    func logGoalAchieved(goalType: String, achievedValue: Double) {
        Analytics.logEvent("goal_achieved", parameters: [
            "goal_type": goalType,
            "achieved_value": achievedValue
        ])
    }
    
    // MARK: - 운동 관련 추가 이벤트
    
    /// 운동 일정 추가 이벤트 로깅
    func logWorkoutScheduled(workoutId: String, workoutName: String, scheduledDay: String) {
        Analytics.logEvent("workout_scheduled", parameters: [
            "workout_id": workoutId,
            "workout_name": workoutName,
            "scheduled_day": scheduledDay
        ])
    }
    
    /// 개인 최고 기록(PR) 달성 이벤트 로깅
    func logPersonalRecordAchieved(exerciseName: String, recordType: String, previousValue: Double, newValue: Double) {
        Analytics.logEvent("personal_record_achieved", parameters: [
            "exercise_name": exerciseName,
            "record_type": recordType,
            "previous_value": previousValue,
            "new_value": newValue,
            "improvement_percentage": ((newValue - previousValue) / previousValue) * 100
        ])
    }
    
    /// 체중 업데이트 이벤트 로깅
    func logWeightUpdated(previousWeight: Double?, newWeight: Double) {
        var parameters: [String: Any] = [
            "new_weight_kg": newWeight
        ]
        
        if let previousWeight = previousWeight {
            parameters["previous_weight_kg"] = previousWeight
            parameters["weight_change"] = newWeight - previousWeight
        }
        
        Analytics.logEvent("weight_updated", parameters: parameters)
    }
    
    /// 앱 사용 시간 기록
    func logAppUsageTime(sessionDuration: TimeInterval, featureUsed: [String]) {
        Analytics.logEvent("app_usage_time", parameters: [
            "session_duration_seconds": sessionDuration,
            "features_used": featureUsed.joined(separator: ",")
        ])
    }
    
    /// 운동 검색 이벤트 로깅
    func logExerciseSearch(searchQuery: String, resultsCount: Int) {
        Analytics.logEvent("exercise_search", parameters: [
            "search_query": searchQuery,
            "results_count": resultsCount
        ])
    }
    
    /// 캘린더 상호작용 이벤트 로깅
    func logCalendarInteraction(interactionType: String, dateSelected: String) {
        Analytics.logEvent("calendar_interaction", parameters: [
            "interaction_type": interactionType,
            "date_selected": dateSelected
        ])
    }
    
    /// 운동 루틴 수정 이벤트 로깅
    func logWorkoutEdited(workoutId: String, workoutName: String, changedFields: [String], exercisesAdded: Int, exercisesRemoved: Int) {
        Analytics.logEvent("workout_edited", parameters: [
            "workout_id": workoutId,
            "workout_name": workoutName,
            "changed_fields": changedFields.joined(separator: ","),
            "exercises_added": exercisesAdded,
            "exercises_removed": exercisesRemoved
        ])
    }
    
    /// 예정된 운동 알림 상호작용 로깅
    func logScheduledWorkoutNotificationInteraction(workoutId: String, action: String) {
        Analytics.logEvent("workout_notification_interaction", parameters: [
            "workout_id": workoutId,
            "action": action // "opened", "dismissed", "snoozed" 등
        ])
    }

    // MARK: - 사용자 속성 관리
    
    /// 사용자 ID 설정
    func setUserId(_ userId: String?) {
        Analytics.setUserID(userId)
    }
    
    /// 사용자 속성 설정
    func setUserProperty(name: String, value: String?) {
        Analytics.setUserProperty(value, forName: name)
    }
    
    /// 사용자 운동 레벨 설정
    func setUserFitnessLevel(level: String) {
        Analytics.setUserProperty(level, forName: "fitness_level")
    }
    
    /// 사용자 선호 운동 종류 설정
    func setUserPreferredWorkoutTypes(types: [String]) {
        Analytics.setUserProperty(types.joined(separator: ","), forName: "preferred_workout_types")
    }
    
    /// 사용자 운동 빈도 설정
    func setUserWorkoutFrequency(timesPerWeek: Int) {
        Analytics.setUserProperty("\(timesPerWeek)", forName: "workout_frequency_per_week")
    }
}