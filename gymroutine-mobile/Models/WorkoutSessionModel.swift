//
//  WorkoutSessionModel.swift
//  gymroutine-mobile
//
//  Created by 森祐樹 on 2025/05/11.
//

import Foundation

// 워크아웃 세션 모델 (결과 저장 및 표시에 사용)
struct WorkoutSessionModel: Codable {
    let workout: Workout // 원본 워크아웃 데이터
    let startTime: Date
    var elapsedTime: TimeInterval
    var completedSets: Set<String> = [] // 완료된 세트 정보 ("exerciseIndex-setIndex")
    var totalRestTime: TimeInterval = 0 // total rest time in seconds
    // TODO: add actual exercise data (weight, reps, etc.) if needed

    // UserDefaults用のエンコード
    func encodeForUserDefaults() -> [String: Any] {
        var sessionData: [String: Any] = [:]

        // Workoutのプロパティを個別に保存
        sessionData["workoutId"] = workout.id
        sessionData["workoutUserId"] = workout.userId
        sessionData["workoutName"] = workout.name
        sessionData["workoutCreatedAt"] = workout.createdAt.timeIntervalSince1970
        sessionData["workoutNotes"] = workout.notes
        sessionData["workoutIsRoutine"] = workout.isRoutine
        sessionData["workoutScheduledDays"] = workout.scheduledDays

        // エクササイズデータを保存
        let exercisesData = workout.exercises.map { exercise -> [String: Any] in
            var exerciseData: [String: Any] = [
                "name": exercise.name,
                "part": exercise.part,
                "key": exercise.key,
                "sets": exercise.sets.map { set -> [String: Any] in
                    [
                        "reps": set.reps,
                        "weight": set.weight
                    ]
                }
            ]
            if let restTime = exercise.restTime {
                exerciseData["restTime"] = restTime
            }
            return exerciseData
        }
        sessionData["workoutExercises"] = exercisesData

        // その他のセッションデータを保存
        sessionData["startTime"] = startTime.timeIntervalSince1970
        sessionData["elapsedTime"] = elapsedTime
        sessionData["completedSets"] = Array(completedSets)
        sessionData["totalRestTime"] = totalRestTime

        return sessionData
    }

    // UserDefaultsからのデコード
    static func decodeFromUserDefaults(_ data: [String: Any]) throws -> WorkoutSessionModel {
        // Workoutの復元
        let workout = Workout(
            id: data["workoutId"] as? String,
            userId: data["workoutUserId"] as! String,
            name: data["workoutName"] as! String,
            createdAt: Date(timeIntervalSince1970: data["workoutCreatedAt"] as! TimeInterval),
            notes: data["workoutNotes"] as? String,
            isRoutine: data["workoutIsRoutine"] as! Bool,
            scheduledDays: data["workoutScheduledDays"] as! [String],
            exercises: (data["workoutExercises"] as! [[String: Any]]).map { exerciseData in
                WorkoutExercise(
                    name: exerciseData["name"] as! String,
                    part: exerciseData["part"] as! String,
                    key: exerciseData["key"] as! String,
                    sets: (exerciseData["sets"] as! [[String: Any]]).map { setData in
                        ExerciseSet(
                            reps: setData["reps"] as! Int,
                            weight: setData["weight"] as! Double
                        )
                    },
                    restTime: exerciseData["restTime"] as? Int
                )
            }
        )

        // セッションの復元
        return WorkoutSessionModel(
            workout: workout,
            startTime: Date(timeIntervalSince1970: data["startTime"] as! TimeInterval),
            elapsedTime: data["elapsedTime"] as! TimeInterval,
            completedSets: Set(data["completedSets"] as! [String]),
            totalRestTime: data["totalRestTime"] as! TimeInterval
        )
    }
}
