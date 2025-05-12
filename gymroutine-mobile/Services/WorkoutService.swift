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
    
    /// 既存ワークアウトの曜日データを更新（新しい構造ではScheduledDaysは[String]タイプ）
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
        // 月別サブコレクションパスを作成 (YYYYMM)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMM"
        let monthCollectionId = dateFormatter.string(from: result.createdAt.dateValue())
        
        // Firestoreパス設定 - ドキュメントID自動生成
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
    ///   - month: 照会する月 (YYYYMM形式の文字列)
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

    /// ワークアウトの基本情報（名前、メモなど）を更新するメソッド
    func updateWorkoutInfo(workoutID: String, name: String, notes: String?, scheduledDays: [String]? = nil) async -> Result<Void, Error> {
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
            
            // ルーチンの曜日がある場合は追加
            if let scheduledDays = scheduledDays {
                updateData["scheduledDays"] = scheduledDays
            }
            
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
