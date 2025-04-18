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
    
    /// 기존 워크아웃 도큐먼트의 요일 데이터를 업데이트 (새로운 구조에서는 ScheduledDays는 [String] 타입)
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
    
    /// 워크아웃의 exercises 필드를 업데이트하는 메서드
    func updateWorkoutExercises(workoutID: String, exercises: [WorkoutExercise]) async -> Result<Void, Error> {
        do {
            // Convert WorkoutExercise objects to Firestore-compatible dictionaries
            let exercisesData = exercises.map { exercise -> [String: Any] in
                var exerciseDict: [String: Any] = [
                    "id": exercise.id,
                    "name": exercise.name,
                    "part": exercise.part
                ]
                
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
            print("🔥 워크아웃 exercises 업데이트 에러: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    /// 워크아웃에 운동을 추가하는 메서드 (새로운 운동 구조: name, part, 그리고 빈 Sets 배열)
    func addExerciseToWorkout(workoutID: String, exercise: WorkoutExercise, completion: @escaping (Bool) -> Void) {
        let exerciseData: [String: Any] = [
            "id": exercise.id,         // 고유 ID 저장
            "name": exercise.name,
            "part": exercise.part,
            "Sets": [] // 초기 세트 배열 (빈 배열)
        ]
        
        db.collection("Workouts").document(workoutID).updateData([
            "exercises": FieldValue.arrayUnion([exerciseData])
        ]) { error in
            if let error = error {
                print("🔥 에크서사이즈 추가 에러: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ 에크서사이즈가 정상적으로 추가되었습니다!")
                completion(true)
            }
        }
    }
    
    /// 워크아웃 상세 정보를 불러오는 메서드 (exercises 필드도 디코딩)
    func fetchWorkoutById(workoutID: String) async throws -> Workout {
        let documentSnapshot = try await db.collection("Workouts").document(workoutID).getDocument()
        
        guard documentSnapshot.exists else {
            throw NSError(domain: "Firestore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Workout not found"])
        }
        
        // Firestore 문서를 Workout 모델로 변환
        do {
            var workout = try documentSnapshot.data(as: Workout.self)
            workout.id = documentSnapshot.documentID
            return workout
        } catch {
            print("🔥 워크아웃 디코딩 에러: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 引数のユーザーが登録済みのワークアウトを全て取得
    func fetchUserWorkouts(uid: String) async -> [Workout]? {
        let db = Firestore.firestore()
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
    
    /// 운동 옵션(Trains 컬렉션) 불러오기
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
    
    /// 특정 트레인의 운동 목록 불러오기
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
    
    /// 워크아웃 결과를 Firestore에 저장하는 함수
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - result: 저장할 WorkoutResultModel 데이터
    func saveWorkoutResult(userId: String, result: WorkoutResultModel) async -> Result<Void, Error> {
        // 월별 서브 컬렉션 경로 생성 (YYYYMM)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMM"
        let monthCollectionId = dateFormatter.string(from: result.createdAt.dateValue())
        
        // Firestore 경로 설정 - 문서 ID 자동 생성
        let resultDocRef = db.collection("Result")
            .document(userId)
            .collection(monthCollectionId)
            .document() // << 문서 ID 자동 생성을 위해 인자 없이 호출
        
        do {
            // WorkoutResultModel을 Firestore에 직접 인코딩하여 저장
            // 자동 생성된 ID를 모델에 저장할 필요는 없지만, 필요 시 resultDocRef.documentID로 접근 가능
            try resultDocRef.setData(from: result) // merge는 새 문서이므로 불필요
            print("✅ 워크아웃 결과 저장 성공: \(userId) / \(monthCollectionId) / \(resultDocRef.documentID)") // 자동 생성 ID 로그 출력
            return .success(())
        } catch {
            print("🔥 워크아웃 결과 저장 실패: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    // MARK: - Workout Result Fetching

    /// 특정 사용자의 특정 월의 특정 운동 결과를 ID로 가져오는 함수
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - month: 조회할 월 (YYYYMM 형식 문자열)
    ///   - resultId: 가져올 결과의 문서 ID
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
            print("✅ Successfully fetched workout result: \(resultId)")
            return result
        } catch {
            print("🔥 Error fetching workout result \(resultId): \(error.localizedDescription)")
            throw error
        }
    }
    
    // TODO: Consider adding a function to fetch all results for a given month or date range if needed for Calendar view etc.
}
