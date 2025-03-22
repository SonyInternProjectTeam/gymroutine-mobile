//
//  WorkoutDetailViewModel.swift
//  gymroutine-mobile
//
//  Created by sony on 2025/01/05.
//

import Foundation
import FirebaseFirestore

/// ワークアウト詳細情報およびエクササイズの管理を行う ViewModel
class WorkoutDetailViewModel: ObservableObject {
    /// 取得したワークアウトの情報を保持する
    @Published var workout: Workout?
    /// 取得したワークアウトに紐づくエクササイズリストを保持する
    @Published var exercises: [WorkoutExercise] = []
    
    /// Firestore の参照
    private let db = Firestore.firestore()
    
    // MARK: - ワークアウト詳細情報取得
    
    /// 指定したワークアウトIDの詳細情報を Firestore から取得する
    /// - Parameter workoutID: ワークアウトのドキュメントID
    func fetchWorkoutDetails(workoutID: String) {
        let docRef = db.collection("Workouts").document(workoutID)
        docRef.getDocument { snapshot, error in
            // ドキュメントの存在チェックとエラー確認
            guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data(), error == nil else {
                print("🔥 ワークアウト取得エラー: \(error?.localizedDescription ?? "不明なエラー")")
                return
            }
            
            // Firestore から各フィールドの値を取り出す
            let userId = data["userId"] as? String ?? ""
            let isRoutine = data["isRoutine"] as? Bool ?? false
            let scheduledDays = data["ScheduledDays"] as? [String] ?? []
            let notes = data["notes"] as? String ?? ""
            // 作成日時は "CreatedAt" キーで保存されている前提
            let createdAt = (data["CreatedAt"] as? Timestamp)?.dateValue() ?? Date()
            
            // 取得したデータから Workout オブジェクトを生成する
            DispatchQueue.main.async {
                self.workout = Workout(
                    id: snapshot.documentID,
                    userId: userId,
                    name: data["name"] as? String ?? "Unknown",
                    isRoutine: isRoutine,
                    scheduledDays: scheduledDays,
                    exercises: [], // 初期状態は空配列。後でエクササイズリストを更新する。
                    createdAt: createdAt,
                    notes: notes
                )
            }
            
            // 同時にエクササイズリストを取得する
            self.fetchExercises(for: workoutID)
        }
    }
    
    // MARK: - エクササイズリスト取得
    
    /// 指定したワークアウトIDに紐づくエクササイズリストを Firestore から取得する
    /// - Parameter workoutID: ワークアウトのドキュメントID
    func fetchExercises(for workoutID: String) {
        let docRef = db.collection("Workouts").document(workoutID)
        docRef.getDocument { snapshot, error in
            // ドキュメント取得のエラーチェック
            guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data(), error == nil else {
                print("🔥 エクササイズ取得エラー: \(error?.localizedDescription ?? "不明なエラー")")
                return
            }
            
            // "exercises" フィールドが配列の辞書形式で保存されている前提
            if let exerciseList = data["exercises"] as? [[String: Any]] {
                // 各エクササイズ辞書から WorkoutExercise オブジェクトに変換する
                let exercises = exerciseList.compactMap { exerciseData -> WorkoutExercise? in
                    // 「id」フィールドも必須として取得する
                    guard let id = exerciseData["id"] as? String,
                          let name = exerciseData["name"] as? String,
                          let part = exerciseData["part"] as? String else {
                        return nil
                    }
                    
                    // オプションフィールド (description, img) の取得（必要に応じて）
                    let description = exerciseData["description"] as? String ?? ""
                    let img = exerciseData["img"] as? String ?? ""
                    
                    // "Sets" キーから各セット情報（辞書の配列）を取得する
                    let setsData = exerciseData["Sets"] as? [[String: Any]] ?? []
                    let sets: [ExerciseSet] = setsData.compactMap { setData in
                        guard let reps = setData["reps"] as? Int,
                              let weightValue = setData["weight"] else {
                            return nil
                        }
                        let weight: Double
                        if let w = weightValue as? Double {
                            weight = w
                        } else if let w = weightValue as? Int {
                            weight = Double(w)
                        } else {
                            weight = 0.0
                        }
                        return ExerciseSet(reps: reps, weight: weight)
                    }
                    
                    return WorkoutExercise(
                        id: id,
                        name: name,
                        part: part,
                        sets: sets
                    )
                }
                
                // メインスレッドでエクササイズリストを更新する
                DispatchQueue.main.async {
                    self.exercises = exercises
                    // 既存のワークアウトオブジェクトにエクササイズリストを反映する
                    if let currentWorkout = self.workout {
                        let updatedWorkout = Workout(
                            id: currentWorkout.id,
                            userId: currentWorkout.userId,
                            name: currentWorkout.name,
                            isRoutine: currentWorkout.isRoutine,
                            scheduledDays: currentWorkout.scheduledDays,
                            exercises: exercises,
                            createdAt: currentWorkout.createdAt,
                            notes: currentWorkout.notes
                        )
                        self.workout = updatedWorkout
                    }
                }
            }
        }
    }
    
    
    // MARK: - エクササイズ追加
    
    /// 指定したワークアウトに新たなエクササイズを追加する
    /// - Parameters:
    ///   - workoutID: ワークアウトのドキュメントID
    ///   - exercise: 追加する WorkoutExercise オブジェクト
    func addExerciseToWorkout(workoutID: String, exercise: WorkoutExercise) {
        let exerciseData: [String: Any] = [
            "id": exercise.id,
            "name": exercise.name,
            "part": exercise.part,
            "Sets": [] // 初期セット配列（空の配列）
        ]
        
        db.collection("Workouts").document(workoutID).updateData([
            "exercises": FieldValue.arrayUnion([exerciseData])
        ]) { error in
            if let error = error {
                print("🔥 エクササイズ追加エラー: \(error.localizedDescription)")
            } else {
                print("✅ エクササイズが正常に追加されました！")
                DispatchQueue.main.async {
                    self.fetchExercises(for: workoutID)
                }
            }
        }
    }
    
    
    // MARK: - エクササイズ更新 TODO
    
    /// 指定したワークアウト内のエクササイズ情報（セット情報など）を更新する
    /// - Parameters:
    ///   - workoutID: ワークアウトのドキュメントID
    ///   - updatedExercise: 更新後の WorkoutExercise オブジェクト
    func updateExercise(workoutID: String, updatedExercise: WorkoutExercise) {
        // 모든 set를 그대로 유지하되, 업데이트 버튼을 누를 때 새로운 0 rep/weight set이 추가되지 않도록 함
        let exerciseToUpdate = updatedExercise
        
        let docRef = db.collection("Workouts").document(workoutID)
        
        // 現在のワークアウトドキュメントを取得する
        docRef.getDocument { snapshot, error in
            guard let snapshot = snapshot, snapshot.exists,
                  var exercisesArray = snapshot.data()?["exercises"] as? [[String: Any]],
                  error == nil else {
                print("🔥 ワークアウト取得エラー（更新用）: \(error?.localizedDescription ?? "不明なエラー")")
                return
            }
            
            // 固有IDを使用して更新対象のエクササイズを探す
            if let index = exercisesArray.firstIndex(where: { ($0["id"] as? String) == exerciseToUpdate.id }) {
                // sets 배열을 사전 배열로 변환 - 새로 추가된 reps:0, weight:0인 세트는 필터링
                let setsArray = exerciseToUpdate.sets.map { set in
                    return [
                        "id": set.id,
                        "reps": set.reps,
                        "weight": set.weight
                    ]
                }
                // 対象エクササイズの "Sets" キー를 업데이트
                exercisesArray[index]["Sets"] = setsArray
                
                // Firestore 의 문서를 업데이트
                docRef.updateData(["exercises": exercisesArray]) { error in
                    if let error = error {
                        print("🔥 エクササイズ更新エラー: \(error.localizedDescription)")
                    } else {
                        print("✅ エクササイズが正常に更新されました: \(exerciseToUpdate.name)")
                        DispatchQueue.main.async {
                            self.fetchExercises(for: workoutID)
                        }
                    }
                }
            } else {
                print("エクササイズが見つかりませんでした。")
            }
        }
    }
    
    /// TODO
    func deleteExercise(workoutID: String, exerciseID: String) {
        let docRef = db.collection("Workouts").document(workoutID)
        
        docRef.getDocument { snapshot, error in
            guard let snapshot = snapshot, snapshot.exists,
                  var exercisesArray = snapshot.data()?["exercises"] as? [[String: Any]],
                  error == nil else {
                print("🔥 エクササイズ削除エラー: \(error?.localizedDescription ?? "不明なエラー")")
                return
            }
            
            exercisesArray.removeAll { ($0["id"] as? String) == exerciseID }
            
            docRef.updateData(["exercises": exercisesArray]) { error in
                if let error = error {
                    print("🔥 エクササイズ削除エラー: \(error.localizedDescription)")
                } else {
                    print("✅ エクササイズ削除完了: \(exerciseID)")
                    DispatchQueue.main.async {
                        self.fetchExercises(for: workoutID)
                    }
                }
            }
        }
    }
    
    /// 指定したワークアウト内のエクササイズのセットを1つ削除する
    /// - Parameters:
    ///   - workoutID: ワークアウトのドキュメントID
    ///   - exerciseID: 対象エクササイズのID
    ///   - setID: 削除対象のセットID
    func deleteExerciseSet(workoutID: String, exerciseID: String, setID: UUID) {
        let docRef = db.collection("Workouts").document(workoutID)
        
        docRef.getDocument { snapshot, error in
            guard let snapshot = snapshot, snapshot.exists,
                  var exercisesArray = snapshot.data()?["exercises"] as? [[String: Any]],
                  error == nil else {
                print("🔥 セット削除エラー: \(error?.localizedDescription ?? "不明なエラー")")
                return
            }
            
            // 해당 exercise 찾기
            if let exerciseIndex = exercisesArray.firstIndex(where: { ($0["id"] as? String) == exerciseID }) {
                var setsArray = exercisesArray[exerciseIndex]["Sets"] as? [[String: Any]] ?? []
                
                // 특정 setID를 가진 세트 삭제
                setsArray.removeAll { ($0["id"] as? String) == setID.uuidString }
                
                exercisesArray[exerciseIndex]["Sets"] = setsArray
                
                // Firestore 업데이트
                docRef.updateData(["exercises": exercisesArray]) { error in
                    if let error = error {
                        print("🔥 セット削除エラー: \(error.localizedDescription)")
                    } else {
                        print("✅ セット削除成功: \(setID)")
                        DispatchQueue.main.async {
                            self.fetchExercises(for: workoutID)
                        }
                    }
                }
            }
        }
    }
}
