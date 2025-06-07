//
//  WorkoutRepository.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/03/22.
//

import Foundation
import FirebaseFirestore

class WorkoutRepository {
    private let db = Firestore.firestore()
    
    /// 특정 사용자의 워크아웃 목록을 불러옵니다.
    func fetchWorkouts(for userID: String) async throws -> [Workout] {
        print("DEBUG: Fetching workouts for userID: \(userID)")
        let snapshot = try await db.collection("Workouts")
            .whereField("userId", isEqualTo: userID)
            .getDocuments()
        print("DEBUG: Fetched \(snapshot.documents.count) documents from Firestore")
        
        return try snapshot.documents.compactMap { document in
            do {
                let workout = try document.data(as: Workout.self)
                print("DEBUG: Successfully decoded workout: \(workout.name)")
                return workout
            } catch {
                print("DEBUG: Failed to decode workout with documentID \(document.documentID): \(error)")
                return nil
            }
        }
    }
    
    /// 새로운 スケジューリングシステムを지원하는 워크아웃 조회
    func fetchWorkoutsWithSchedule(for userID: String) async throws -> [Workout] {
        print("DEBUG: Fetching workouts with schedule for userID: \(userID)")
        let snapshot = try await db.collection("Workouts")
            .whereField("userId", isEqualTo: userID)
            .getDocuments()
        print("DEBUG: Fetched \(snapshot.documents.count) documents from Firestore")
        
        var workouts: [Workout] = []
        
        for document in snapshot.documents {
            do {
                let workout = try document.data(as: Workout.self)
                print("DEBUG: Successfully decoded workout with new schedule: \(workout.name)")
                workouts.append(workout)
            } catch {
                print("DEBUG: Failed to decode workout with new schedule, attempting legacy parsing: \(error)")
                // 既存構造のデータの場合互換性処理
                if let legacyWorkout = try? parseLegacyWorkout(from: document.data()) {
                    print("DEBUG: Successfully parsed legacy workout: \(legacyWorkout.name)")
                    workouts.append(legacyWorkout)
                } else {
                    print("DEBUG: Failed to parse legacy workout for document: \(document.documentID)")
                }
            }
        }
        
        return workouts
    }
    
    /// 특정 スケジュール타입으로 워크아웃 필터링
    func fetchWorkouts(for userID: String, scheduleType: WorkoutScheduleType) async throws -> [Workout] {
        print("DEBUG: Fetching workouts for userID: \(userID) with scheduleType: \(scheduleType.rawValue)")
        
        let snapshot = try await db.collection("Workouts")
            .whereField("userId", isEqualTo: userID)
            .whereField("schedule.type", isEqualTo: scheduleType.rawValue)
            .getDocuments()
        
        print("DEBUG: Fetched \(snapshot.documents.count) workouts with schedule type: \(scheduleType.rawValue)")
        
        return try snapshot.documents.compactMap { document in
            do {
                let workout = try document.data(as: Workout.self)
                print("DEBUG: Successfully decoded workout: \(workout.name)")
                return workout
            } catch {
                print("DEBUG: Failed to decode workout with documentID \(document.documentID): \(error)")
                return nil
            }
        }
    }
    
    /// 특정 요일에 スケジュールされた 워크아웃 조회
    func fetchWorkouts(for userID: String, weekday: String) async throws -> [Workout] {
        print("DEBUG: Fetching workouts for userID: \(userID) on weekday: \(weekday)")
        
        let snapshot = try await db.collection("Workouts")
            .whereField("userId", isEqualTo: userID)
            .whereField("schedule.weeklyDays", arrayContains: weekday)
            .getDocuments()
        
        print("DEBUG: Fetched \(snapshot.documents.count) workouts for weekday: \(weekday)")
        
        return try snapshot.documents.compactMap { document in
            do {
                let workout = try document.data(as: Workout.self)
                print("DEBUG: Successfully decoded workout: \(workout.name)")
                return workout
            } catch {
                print("DEBUG: Failed to decode workout with documentID \(document.documentID): \(error)")
                return nil
            }
        }
    }
    
    /// 특정 날짜 범위 내의 워크아웃 조회
    func fetchWorkouts(for userID: String, startDate: Date, endDate: Date) async throws -> [Workout] {
        print("DEBUG: Fetching workouts for userID: \(userID) between \(startDate) and \(endDate)")
        
        let snapshot = try await db.collection("Workouts")
            .whereField("userId", isEqualTo: userID)
            .getDocuments()
        
        let allWorkouts = try snapshot.documents.compactMap { document in
            try? document.data(as: Workout.self)
        }
        
        // 클라이언트 사이드에서 날짜 범위 필터링
        let filteredWorkouts = allWorkouts.filter { workout in
            isWorkoutInDateRange(workout: workout, startDate: startDate, endDate: endDate)
        }
        
        print("DEBUG: Filtered \(filteredWorkouts.count) workouts in date range")
        return filteredWorkouts
    }
    
    /// 기간이 設定された コーチアウトのみを取得
    func fetchWorkoutsWithDuration(for userID: String) async throws -> [Workout] {
        print("DEBUG: Fetching workouts with duration for userID: \(userID)")
        
        let allWorkouts = try await fetchWorkoutsWithSchedule(for: userID)
        
        let workoutsWithDuration = allWorkouts.filter { $0.duration != nil }
        
        print("DEBUG: Found \(workoutsWithDuration.count) workouts with duration")
        return workoutsWithDuration
    }
    
    /// 期限切れのコーチアウトを取得 (期間が終了したコーチアウトのみ)
    func fetchExpiredWorkouts(for userID: String) async throws -> [Workout] {
        print("DEBUG: Fetching expired workouts for userID: \(userID)")
        
        let workoutsWithDuration = try await fetchWorkoutsWithDuration(for: userID)
        let currentDate = Date()
        
        let expiredWorkouts = workoutsWithDuration.filter { workout in
            guard let duration = workout.duration else { return false }
            
            if let endDate = duration.endDate {
                return endDate < currentDate
            }
            
            // 総回数または週単位で設定された場合の期限チェックロジック
            // 実際の実装ではWorkoutResultデータと比較して判断する必要があります
            // ここでは基本的な構造のみを提供
            return false
        }
        
        print("DEBUG: Found \(expiredWorkouts.count) expired workouts")
        return expiredWorkouts
    }
    
    // MARK: - Helper Methods
    
    /// 既存構造のコーチアウトデータを新しい構造に変換
    private func parseLegacyWorkout(from data: [String: Any]) throws -> Workout {
        guard let userId = data["userId"] as? String,
              let name = data["name"] as? String,
              let createdAtTimestamp = data["createdAt"] as? Timestamp else {
            throw NSError(domain: "LegacyConversion", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
        }
        
        let createdAt = createdAtTimestamp.dateValue()
        let notes = data["notes"] as? String
        let isRoutine = data["isRoutine"] as? Bool ?? false
        let scheduledDays = data["scheduledDays"] as? [String] ?? []
        
        // 既存データを新しいスケジュールシステムに変換
        let schedule: WorkoutSchedule
        if isRoutine && !scheduledDays.isEmpty {
            schedule = WorkoutSchedule(
                type: .weekly,
                weeklyDays: scheduledDays,
                intervalDays: nil,
                startDate: createdAt,
                specificDates: nil
            )
        } else {
            schedule = WorkoutSchedule(
                type: .oneTime,
                weeklyDays: nil,
                intervalDays: nil,
                startDate: createdAt,
                specificDates: nil
            )
        }
        
        // exercises パース
        var exercises: [WorkoutExercise] = []
        if let exercisesData = data["exercises"] as? [[String: Any]] {
            exercises = exercisesData.compactMap { exerciseData in
                parseWorkoutExercise(from: exerciseData)
            }
        }
        
        return Workout(
            userId: userId,
            name: name,
            createdAt: createdAt,
            notes: notes,
            schedule: schedule,
            duration: nil,
            exercises: exercises
        )
    }
    
    /// WorkoutExercise データ パース
    private func parseWorkoutExercise(from data: [String: Any]) -> WorkoutExercise? {
        guard let name = data["name"] as? String,
              let part = data["part"] as? String,
              let key = data["key"] as? String else {
            return nil
        }
        
        let id = data["id"] as? String ?? UUID().uuidString
        let restTime = data["restTime"] as? Int
        
        var sets: [ExerciseSet] = []
        if let setsData = data["sets"] as? [[String: Any]] {
            sets = setsData.compactMap { setData in
                guard let reps = setData["reps"] as? Int,
                      let weight = setData["weight"] as? Double else {
                    return nil
                }
                return ExerciseSet(reps: reps, weight: weight)
            }
        }
        
        return WorkoutExercise(
            id: id,
            name: name,
            part: part,
            key: key,
            sets: sets,
            restTime: restTime
        )
    }
    
    /// コーチアウトが特定の日付範囲内にあるかどうかを確認
    private func isWorkoutInDateRange(workout: Workout, startDate: Date, endDate: Date) -> Bool {
        let schedule = workout.schedule
        
        switch schedule.type {
        case .oneTime:
            guard let workoutDate = schedule.startDate else { return false }
            return workoutDate >= startDate && workoutDate <= endDate
            
        case .weekly:
            // 毎週繰り返しの場合は開始日が範囲内にあるか、範囲内の週に該当する曜日があるかを確認
            guard let startWorkoutDate = schedule.startDate else { return false }
            
            // コーチアウト開始日が範囲内にある場合はtrue
            if startWorkoutDate >= startDate && startWorkoutDate <= endDate {
                return true
            }
            
            // 範囲内の日付の中に該当する曜日があるかを確認
            let calendar = Calendar.current
            var currentDate = max(startDate, startWorkoutDate)
            
            while currentDate <= endDate {
                let weekday = calendar.component(.weekday, from: currentDate)
                let weekdayString = getWeekdayString(from: weekday)
                
                if schedule.weeklyDays?.contains(weekdayString) == true {
                    return true
                }
                
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            
            return false
            
        case .interval:
            guard let startWorkoutDate = schedule.startDate,
                  let intervalDays = schedule.intervalDays else { return false }
            
            // 間隔繰り返しの場合は開始日から間隔で計算された日付が範囲内にあるかを確認
            var currentDate = startWorkoutDate
            
            while currentDate <= endDate {
                if currentDate >= startDate && currentDate <= endDate {
                    return true
                }
                
                guard let nextDate = Calendar.current.date(byAdding: .day, value: intervalDays, to: currentDate) else {
                    break
                }
                currentDate = nextDate
            }
            
            return false
            
        case .specificDates:
            guard let specificDates = schedule.specificDates else { return false }
            
            return specificDates.contains { date in
                date >= startDate && date <= endDate
            }
        }
    }
    
    /// weekday 数字を文字列に変換 (1: Sunday, 2: Monday, ...)
    private func getWeekdayString(from weekday: Int) -> String {
        switch weekday {
        case 1: return "Sunday"
        case 2: return "Monday"
        case 3: return "Tuesday"
        case 4: return "Wednesday"
        case 5: return "Thursday"
        case 6: return "Friday"
        case 7: return "Saturday"
        default: return "Monday"
        }
    }
}
