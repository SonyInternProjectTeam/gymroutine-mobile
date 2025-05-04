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
    
    // MARK: - 사용자 속성 관리
    
    /// 사용자 ID 설정
    func setUserId(_ userId: String?) {
        Analytics.setUserID(userId)
    }
    
    /// 사용자 속성 설정
    func setUserProperty(name: String, value: String?) {
        Analytics.setUserProperty(value, forName: name)
    }
}