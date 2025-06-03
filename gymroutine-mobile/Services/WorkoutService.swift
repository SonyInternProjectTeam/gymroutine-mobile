//
//  WorkoutService.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/11/08.
//

import Foundation
import Firebase
import FirebaseFirestore

class WorkoutService {
    private let db = Firestore.firestore()
    
    // ワークアウトを作成(Create)
    func createWorkout(workout: Workout) async -> Result<Void, Error> {
        let workoutDocumentRef = db.collection("Workouts").document()
        
        do {
            try workoutDocumentRef.setData(from: workout)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    /// 새로운 スケジューリングシステムを사용하여 워크아웃 스케줄을 업데이트
    func updateWorkoutSchedule(workoutID: String, schedule: WorkoutSchedule, duration: WorkoutDuration?) async -> Result<Void, Error> {
        do {
            var updateData: [String: Any] = [:]
            
            // 새로운 스케줄 정보 인코딩
            let scheduleData = try Firestore.Encoder().encode(schedule)
            updateData["schedule"] = scheduleData
            
            // 기간 정보가 있으면 추가
            if let duration = duration {
                let durationData = try Firestore.Encoder().encode(duration)
                updateData["duration"] = durationData
            } else {
                updateData["duration"] = FieldValue.delete()
            }
            
            // 기존 호환성 필드들도 업데이트
            updateData["isRoutine"] = schedule.type != .oneTime
            updateData["scheduledDays"] = schedule.weeklyDays ?? []
            
            try await db.collection("Workouts").document(workoutID).updateData(updateData)
            return .success(())
        } catch {
            print("🔥 ワークアウトスケジュール更新エラー: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    /// 既存ワークアウトの曜日データを更新（新しい構造ではScheduledDaysは[String]タイプ）
    /// 기존 호환성을 위해 유지하지만 새로운 updateWorkoutSchedule 사용 권장
    @available(*, deprecated, message: "Use updateWorkoutSchedule instead")
    func updateScheduledDaysForWorkout(workoutID: String, scheduledDays: [String], completion: @escaping (Bool) -> Void) {
        db.collection("Workouts").document(workoutID).updateData([
            "ScheduledDays": scheduledDays
        ]) { error in
            if let error = error {
                print("Error updating scheduled days: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    /// ワークアウトのexercisesフィールドを更新するメソッド
    func updateWorkoutExercises(workoutID: String, exercises: [WorkoutExercise]) async -> Result<Void, Error> {
        do {
            // Convert WorkoutExercise objects to Firestore-compatible dictionaries
            let exercisesData = exercises.map { exercise -> [String: Any] in
                var exerciseDict: [String: Any] = [
                    "id": exercise.id,
                    "name": exercise.name,
                    "part": exercise.part,
                    "key": exercise.key
                ]
                
                // Add restTime if available
                if let restTime = exercise.restTime {
                    exerciseDict["restTime"] = restTime
                }
                
                // Convert sets to array of dictionaries
                let setsArray = exercise.sets.map { set -> [String: Any] in
                    return [
                        "reps": set.reps,
                        "weight": set.weight
                    ]
                }
                
                exerciseDict["sets"] = setsArray
                return exerciseDict
            }
            
            try await db.collection("Workouts").document(workoutID).updateData([
                "exercises": exercisesData
            ])
            return .success(())
        } catch {
            print("🔥 ワークアウトexercises更新エラー: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    /// ワークアウトに運動を追加するメソッド（新しい運動構造: name, part, そして空のSets配列）
    func addExerciseToWorkout(workoutID: String, exercise: WorkoutExercise, completion: @escaping (Bool) -> Void) {
        var exerciseData: [String: Any] = [
            "id": exercise.id,         // 一意のID保存
            "name": exercise.name,
            "part": exercise.part,
            "key": exercise.key,
            "sets": []  // 初期セット配列（空配列）
        ]
        
        // Add restTime if available
        if let restTime = exercise.restTime {
            exerciseData["restTime"] = restTime
        }
        
        db.collection("Workouts").document(workoutID).updateData([
            "exercises": FieldValue.arrayUnion([exerciseData])
        ]) { error in
            if let error = error {
                print("🔥 エクササイズ追加エラー: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ エクササイズが正常に追加されました!")
                completion(true)
            }
        }
    }
    
    func fetchWorkoutById(workoutID: String) async -> Result<Workout, Error> {
        let workoutRef = db.collection("Workouts").document(workoutID)

        do {
            let snapshot = try await workoutRef.getDocument()
            print(snapshot)
            do {
                let workout = try snapshot.data(as: Workout.self)
                return .success(workout)
            } catch {
                return .failure(NSError(domain: "Firestore", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Decode Error"]))
            }
        } catch {
            return .failure(NSError(domain: "Firestore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Workout not found"]))
        }
    }
    
    /// 引数のユーザーが登録済みのワークアウトを全て取得
    func fetchUserWorkouts(uid: String) async -> [Workout]? {
        let workoutsRef = db.collection("Workouts").whereField("userId", isEqualTo: uid)
        
        do {
            let snapshot = try await workoutsRef.getDocuments()
            var workouts: [Workout] = []
            
            for document in snapshot.documents {
                do {
                    let workout = try document.data(as: Workout.self)
                    workouts.append(workout)
                } catch {
                    print("[ERROR] Workoutのデコードエラー: \(error)")
                }
            }
            return workouts
            
        } catch {
            print("[ERROR] Firestore 取得エラー: \(error)")
            return nil
        }
    }
    
    /// 新로운 スケジューリングシステムを지원하는 사용자 워크아웃 조회 메서드
    func fetchUserWorkoutsWithSchedule(uid: String) async -> Result<[Workout], Error> {
        do {
            let snapshot = try await db.collection("Workouts")
                .whereField("userId", isEqualTo: uid)
                .getDocuments()
            
            var workouts: [Workout] = []
            
            for document in snapshot.documents {
                do {
                    let workout = try document.data(as: Workout.self)
                    workouts.append(workout)
                } catch {
                    print("[ERROR] 워크아웃 디코딩 에러: \(error)")
                    // 기존 구조의 데이터인 경우 호환성 처리
                    if let legacyWorkout = try? self.parseLegacyWorkout(from: document.data()) {
                        workouts.append(legacyWorkout)
                    }
                }
            }
            
            return .success(workouts)
        } catch {
            print("[ERROR] Firestore 조회 에러: \(error)")
            return .failure(error)
        }
    }
    
    /// 기존 구조의 워크아웃 데이터를 새로운 구조로 변환
    private func parseLegacyWorkout(from data: [String: Any]) throws -> Workout {
        // 이 메서드는 기존 데이터가 새로운 schedule 필드가 없을 때 호환성을 제공합니다
        // 실제 구현에서는 기존 isRoutine, scheduledDays 필드를 사용해 WorkoutSchedule을 생성
        // 여기서는 기본 구현만 제공하고, 필요에 따라 세부 구현을 추가하세요
        throw NSError(domain: "LegacyConversion", code: 1, userInfo: [NSLocalizedDescriptionKey: "Legacy workout conversion not implemented"])
    }
    
    /// 특정 スケジュール タイプ으로 워크아웃 필터링
    func fetchWorkoutsByScheduleType(uid: String, scheduleType: WorkoutScheduleType) async -> Result<[Workout], Error> {
        do {
            let snapshot = try await db.collection("Workouts")
                .whereField("userId", isEqualTo: uid)
                .whereField("schedule.type", isEqualTo: scheduleType.rawValue)
                .getDocuments()
            
            let workouts = try snapshot.documents.compactMap { document in
                try document.data(as: Workout.self)
            }
            
            return .success(workouts)
        } catch {
            print("[ERROR] スケジュール タイプ별 워크아웃 조회 에러: \(error)")
            return .failure(error)
        }
    }
    
    /// 특정 요일에 スケジュール된 워크아웃 조회
    func fetchWorkoutsByWeekday(uid: String, weekday: String) async -> Result<[Workout], Error> {
        do {
            let snapshot = try await db.collection("Workouts")
                .whereField("userId", isEqualTo: uid)
                .whereField("schedule.weeklyDays", arrayContains: weekday)
                .getDocuments()
            
            let workouts = try snapshot.documents.compactMap { document in
                try document.data(as: Workout.self)
            }
            
            return .success(workouts)
        } catch {
            print("[ERROR] 요일별 워크아웃 조회 에러: \(error)")
            return .failure(error)
        }
    }
    
    /// 運動オプション(Trainsコレクション)を読み込む
    func fetchTrainOptions(completion: @escaping ([String]) -> Void) {
        db.collection("Trains").getDocuments { (snapshot, error) in
            guard let documents = snapshot?.documents, error == nil else {
                print("Error fetching train options: \(String(describing: error))")
                completion([])
                return
            }
            let options = documents.map { $0.documentID }
            completion(options)
        }
    }
    
    /// 特定トレインの運動リストを読み込む
    func fetchExercises(for train: String, completion: @escaping ([String]) -> Void) {
        db.collection("Trains").document(train).collection("exercises").getDocuments { (snapshot, error) in
            guard let documents = snapshot?.documents, error == nil else {
                print("Error fetching exercises: \(String(describing: error))")
                completion([])
                return
            }
            let exercises = documents.map { $0.documentID }
            completion(exercises)
        }
    }
    
    // MARK: - Workout Result Saving
    
    /// ワークアウト結果をFirestoreに保存する関数
    /// - Parameters:
    ///   - userId: ユーザーID
    ///   - result: 保存するWorkoutResultModelデータ
    func saveWorkoutResult(userId: String, result: WorkoutResultModel) async -> Result<Void, Error> {
        // 월별サブコレクションパスを作成 (YYYYMM)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMM"
        let monthCollectionId = dateFormatter.string(from: result.createdAt.dateValue())
        
        // Firestoreパス設정 - ドキュメントID自動生成
        let resultDocRef = db.collection("Result")
            .document(userId)
            .collection(monthCollectionId)
            .document() // << ドキュメントID自動生成のため引数なしで呼び出し
        
        do {
            // WorkoutResultModelをFirestoreに直接エンコーディングして保存
            // 自動生成されたIDをモデルに保存する必要はないが、必要な場合はresultDocRef.documentIDでアクセス可能
            try resultDocRef.setData(from: result) // 新しいドキュメントなのでmergeは不要
            print("✅ ワークアウト結果保存成功: \(userId) / \(monthCollectionId) / \(resultDocRef.documentID)") // 自動生成ID出力
            return .success(())
        } catch {
            print("🔥 ワークアウト結果保存失敗: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    // MARK: - Workout Result Fetching

    /// 特定ユーザーの特定月の特定運動結果をIDで取得する関数
    /// - Parameters:
    ///   - userId: ユーザーID
    ///   - month: 照회する月 (YYYYMM形式の文字列)
    ///   - resultId: 取得する結果のドキュメントID
    func fetchWorkoutResultById(userId: String, month: String, resultId: String) async throws -> WorkoutResultModel {
        let resultDocRef = db.collection("Result") // Base collection is "Result"
            .document(userId)
            .collection(month) // Subcollection is "YYYYMM"
            .document(resultId)

        do {
            let documentSnapshot = try await resultDocRef.getDocument()
            guard documentSnapshot.exists else {
                throw NSError(domain: "Firestore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Workout result not found for ID: \(resultId) in month \(month)"])
            }
            
            let result = try documentSnapshot.data(as: WorkoutResultModel.self)
            print("✅ ワークアウト結果取得成功: \(resultId)")
            return result
        } catch {
            print("🔥 ワークアウト結果取得エラー \(resultId): \(error.localizedDescription)")
            throw error
        }
    }
    
    // TODO: Consider adding a function to fetch all results for a given month or date range if needed for Calendar view etc.

    // MARK: - Workout Update

    /// 새로운 スケジューリングシステムを지원하는 워크아웃 정보 업데이트 메서드
    func updateWorkoutInfo(workoutID: String, 
                          name: String, 
                          notes: String?, 
                          schedule: WorkoutSchedule? = nil, 
                          duration: WorkoutDuration? = nil) async -> Result<Void, Error> {
        do {
            var updateData: [String: Any] = [
                "name": name
            ]
            
            // 메모 처리
            if let notes = notes, !notes.isEmpty {
                updateData["notes"] = notes
            } else {
                updateData["notes"] = FieldValue.delete()
            }
            
            // 새로운 スケジュール 정보가 제공되면 업데이트
            if let schedule = schedule {
                let scheduleData = try Firestore.Encoder().encode(schedule)
                updateData["schedule"] = scheduleData
                
                // 기존 호환성 필드도 업데이트
                updateData["isRoutine"] = schedule.type != .oneTime
                updateData["scheduledDays"] = schedule.weeklyDays ?? []
            }
            
            // 기간 정보 업데이트
            if let duration = duration {
                let durationData = try Firestore.Encoder().encode(duration)
                updateData["duration"] = durationData
            }
            
            try await db.collection("Workouts").document(workoutID).updateData(updateData)
            return .success(())
        } catch {
            print("🔥 ワークアウト情報更新エラー: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    /// 기존 호환성을 위한 워크아웃 정보 업데이트 메서드 (deprecated)
    @available(*, deprecated, message: "Use updateWorkoutInfo with schedule parameter instead")
    func updateWorkoutInfo(workoutID: String, name: String, notes: String?, scheduledDays: [String] = []) async -> Result<Void, Error> {
        do {
            // 更新するフィールドのみを含める
            var updateData: [String: Any] = [
                "name": name
            ]
            
            // メモがある場合は追加
            if let notes = notes {
                updateData["notes"] = notes
            } else {
                // メモがない場合はフィールドを削除
                updateData["notes"] = FieldValue.delete()
            }
            
                updateData["scheduledDays"] = scheduledDays
                updateData["isRoutine"] = scheduledDays.isEmpty ? false : true
            
            try await db.collection("Workouts").document(workoutID).updateData(updateData)
            return .success(())
        } catch {
            print("🔥 ワークアウト情報の更新エラー: \(error.localizedDescription)")
            return .failure(error)
        }
    }

    /// ワークアウトのエクササイズ順序を並べ替えるメソッド
    func reorderWorkoutExercises(workoutID: String, exercises: [WorkoutExercise]) async -> Result<Void, Error> {
        // 以前のupdateWorkoutExercisesメソッドと同じ動作ですが、目的を明確にするために別メソッドとして実装
        return await updateWorkoutExercises(workoutID: workoutID, exercises: exercises)
    }
    
    // MARK: - Workout Deletion
    
    /// Firestoreからワークアウトドキュメントを削除するメソッド
    func deleteWorkout(workoutID: String) async -> Result<Void, Error> {
        do {
            try await db.collection("Workouts").document(workoutID).delete()
            return .success(())
        } catch {
            print("🔥 ワークアウトの削除エラー (ID: \(workoutID)): \(error.localizedDescription)")
            return .failure(error)
        }
    }
}
