//
//  CalendarViewModel.swift
//  gymroutine-mobile
//
//  Created by SATTSAT on 2025/02/03
//
//

import Foundation
import SwiftUI
import FirebaseFirestore
import Combine

@MainActor
final class CalendarViewModel: ObservableObject {
    
    @Published var months: [Date] = []  //月ごとのDate情報
    @Published var selectedDate: Date = Date()  //選択されている日にち
    @Published var selectedMonth: Date? //Viewに表示されている月
    @Published var workoutsByWeekday: [String: [Workout]] = [:]
    @Published var completedWorkoutsByDate: [String: [WorkoutResult]] = [:] // 完了したワークアウト履歴
    @Published var workoutNames: [String: String] = [:] // workoutIDをキーとするワークアウト名の辞書
    
    private let calendar: Calendar = .current
    private let workoutService = WorkoutService()
    private let userManager = UserManager.shared
    private let db = Firestore.firestore() // Firestore 직접 접근 위해 추가
    private var listenerRegistration: ListenerRegistration? // 리스너 등록 관리 위해 추가
    private var cancellables = Set<AnyCancellable>() // 이것은 다른 구독용으로 남겨둘 수 있음
    
    let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    init() {
        self.months = (-2...2).compactMap { calendar.date(byAdding: .month, value: $0, to: selectedDate) }
        self.selectedMonth = selectedDate
        fetchUserRoutine()
        setupWorkoutHistoryListener() // fetch 대신 리스너 설정 함수 호출
        // subscribeToResultUpdates() // PassthroughSubject 구독 제거
    }
    
    // ViewModel 소멸 시 리스너 제거
    deinit {
        // Task를 사용하여 메인 액터에서 리스너 제거 실행
        Task { @MainActor in
            removeListener()
        }
    }
    
    // 리스너 제거 함수
    func removeListener() {
        listenerRegistration?.remove()
        listenerRegistration = nil
        print("[DEBUG] Workout history listener removed.")
    }
    
    // ワークアウト名を取得（存在しない場合は適切な代替名を返す）
    func getWorkoutName(for result: WorkoutResult) -> String {
        if let workoutId = result.workoutId {
            // キャッシュ済みなら返す
            if let name = workoutNames[workoutId] {
                return name
            }

            // 非同期取得
            Task {
                let response = await workoutService.fetchWorkoutById(workoutID: workoutId)
                switch response {
                case .success(let workout):
                    self.workoutNames[workoutId] = workout.name
                    self.objectWillChange.send()
                case .failure(let error):
                    print("[ERROR] \(error.localizedDescription)")
                    let fallbackName = result.exercises?.first?.exerciseName.appending("のワークアウト") ?? "Quick Start"
                    self.workoutNames[workoutId] = fallbackName
                    self.objectWillChange.send()
                }
            }
            return "ワークアウトを読み込み中..."
        }

        // workoutId がない場合
        if let firstExercise = result.exercises?.first {
            return firstExercise.exerciseName + "のワークアウト"
        }

        return "Quick Start"
    }
    
    func fetchUserRoutine() {
        guard let uid = userManager.currentUser?.uid else {
            print("[ERROR] Currentuidが取得できません")
            return
        }
        
        Task {
            guard let userWorkouts = await workoutService.fetchUserWorkouts(uid: uid) else {
                return
            }
            self.categorizeWorkoutsByWeekday(userWorkouts)
        }
    }
    
    // Firestore 리스너 설정 함수 (기존 fetchWorkoutHistory 대체)
    func setupWorkoutHistoryListener() {
        removeListener() // 기존 리스너가 있다면 제거
        
        guard let uid = userManager.currentUser?.uid else {
            print("[ERROR] Listener setup failed: User ID not available.")
            // 필요하다면 사용자에게 오류 메시지를 표시하거나 재시도 로직 추가
            return
        }
        
        guard let currentMonth = selectedMonth else {
            print("[ERROR] Listener setup failed: Selected month not available.")
            return
        }
        
        // 현재 선택된 달의 년/월 문자열 생성 ("yyyyMM")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMM"
        let currentYearMonth = dateFormatter.string(from: currentMonth)
        
        print("[DEBUG] Setting up listener for workout history in \(currentYearMonth) for user \(uid)")
        
        let monthCollectionRef = db.collection("Result")
            .document(uid)
            .collection(currentYearMonth)
        
        listenerRegistration = monthCollectionRef.addSnapshotListener { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("[ERROR] Failed to listen for workout history updates: \(error.localizedDescription)")
                // TODO: Handle error appropriately (e.g., show alert to user)
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("[DEBUG] No documents found in snapshot for \(currentYearMonth).")
                // 해당 월에 데이터가 없을 수 있으므로 오류는 아님. 해당 월 데이터 초기화.
                self.updateCompletedWorkouts(from: [])
                return
            }
            
            print("[DEBUG] Received snapshot update with \(documents.count) documents for \(currentYearMonth).")
            
            let results: [WorkoutResult] = documents.compactMap { document -> WorkoutResult? in
                do {
                    var result = try document.data(as: WorkoutResult.self)
                    result.id = document.documentID // ID 수동 할당
                    return result
                } catch {
                    print("[ERROR] Failed to decode workout result document \(document.documentID): \(error)")
                    return nil
                }
            }
            
            // ViewModel의 상태 업데이트
            self.updateCompletedWorkouts(from: results)
        }
    }
    
    // 받은 결과로 completedWorkoutsByDate 상태를 업데이트하는 헬퍼 함수
    private func updateCompletedWorkouts(from results: [WorkoutResult]) {
        var workoutsByDate: [String: [WorkoutResult]] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for result in results {
            guard let date = result.createdAt?.dateValue() else { continue }
            let dateString = dateFormatter.string(from: date)
            workoutsByDate[dateString, default: []].append(result)
        }
        
        // 현재 선택된 달에 해당하는 데이터만 업데이트 (혹은 전체 데이터 업데이트 구조 유지)
        // 여기서는 전체를 업데이트하는 기존 방식을 유지합니다.
        DispatchQueue.main.async {
             // 주의: 이 방식은 리스너가 설정된 달의 데이터만 업데이트합니다.
             // 다른 달의 데이터가 필요하다면, 월 변경 시 리스너를 재설정해야 합니다.
             // 또는, 여러 달의 리스너를 동시에 관리하는 더 복잡한 구조가 필요합니다.
            self.completedWorkoutsByDate = workoutsByDate
             print("[DEBUG] Updated completed workouts data: \(self.completedWorkoutsByDate.count) dates with results.")
        }
    }
    
    // 월 변경 시 리스너 재설정
    func onChangeMonth(_ month: Date?) {
        guard let month = month else { return }
        
        print("[DEBUG] Month changed to \(month.formatted(.dateTime.year().month())). Setting up listener...")
        checkAndLoadMoreMonths(for: month) // 이전/다음 달 로딩 로직 (기존 유지)
        setupWorkoutHistoryListener() // 새 달에 대한 리스너 설정
    }
    
    // 스クロール時に前後2ヶ月が確保されるように管理
    func checkAndLoadMoreMonths(for monthDate: Date) {
        if let firstIndex = months.firstIndex(of: monthDate),
           firstIndex == 1 { // 先頭から2番目が表示されたら先月を追加
            loadPreviousMonth()
        }
        
        if let lastIndex = months.firstIndex(of: monthDate),
           lastIndex == months.count - 2 { // 末尾から2番目が表示されたら翌月を追加
            loadNextMonth()
        }
    }
    
    // months配列に先月を追加
    func loadPreviousMonth() {
        if let firstMonth = months.first,
           let prevMonth = calendar.date(byAdding: .month, value: -1, to: firstMonth) {
            months.insert(prevMonth, at: 0)
        }
    }

    // months配列に来月を追加
    func loadNextMonth() {
        if let lastMonth = months.last,
           let nextMonth = calendar.date(byAdding: .month, value: 1, to: lastMonth) {
            months.append(nextMonth)
        }
    }
    
    //曜日indexからその曜日のWorkoutを取得（0 -> 日曜日, 1 -> 月曜日
    func getWorkoutsForWeekday(index: Int) -> [Workout] {
        guard index >= 0, index < weekdays.count else { return [] }
        let weekday = weekdays[index]
        return workoutsByWeekday[weekday] ?? []
    }
    
    // 지정일에 완료된 워크아웃 가져오기
    func getCompletedWorkoutsForDate(_ date: Date) -> [WorkoutResult] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        return completedWorkoutsByDate[dateString] ?? []
    }
    
    // 날짜에 워크아웃 기록 있는지 확인
    func hasCompletedWorkout(on date: Date) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        return completedWorkoutsByDate[dateString]?.isEmpty == false
    }
    
    // userが設定したScheduleDaysから、曜日ごとにカテゴライズ
    private func categorizeWorkoutsByWeekday(_ workouts: [Workout]) {
        var categorizedWorkouts: [String: [Workout]] = [:]
        
        for workout in workouts {
            for scheduledDay in workout.scheduledDays {
                categorizedWorkouts[scheduledDay, default: []].append(workout)
            }
        }
        
        self.workoutsByWeekday = categorizedWorkouts
    }
}
