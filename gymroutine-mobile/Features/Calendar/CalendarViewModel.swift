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
    @Published var workoutsByDate: [String: [Workout]] = [:] // 날짜별 워크아웃 (새로운 스케줄링 시스템 지원)
    @Published var completedWorkoutsByDate: [String: [WorkoutResult]] = [:] // 完了したワークアウト履歴
    @Published var workoutNames: [String: String] = [:] // workoutIDをキーとするワークアウト名の辞書
    @Published var allWorkouts: [Workout] = [] // 모든 워크아웃 캐시
    
    private let calendar: Calendar = .current
    private let workoutService = WorkoutService()
    private let workoutRepository = WorkoutRepository()
    private let userManager = UserManager.shared
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    
    let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    init() {
        self.months = (-2...2).compactMap { calendar.date(byAdding: .month, value: $0, to: selectedDate) }
        self.selectedMonth = selectedDate
        fetchUserRoutine()
        setupWorkoutHistoryListener()
    }
    
    deinit {
        MainActor.assumeIsolated {
            self.removeListener()
        }
    }
    
    // リスナ 제거 함수
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
                    let fallbackName = result.exercises?.first?.exerciseName.appending("のワークアウト") ?? "クイックスタート"
                    self.workoutNames[workoutId] = fallbackName
                    self.objectWillChange.send()
                }
            }
            return "ワークアウト読み込み中..."
        }

        // workoutId が ない場合
        if let firstExercise = result.exercises?.first {
            return firstExercise.exerciseName + "のワークアウト"
        }

        return "クイックスタート"
    }
    
    func fetchUserRoutine() {
        guard let uid = userManager.currentUser?.uid else {
            print("[ERROR] 현재 UIDを取得できません")
            return
        }
        
        Task {
            do {
                // 새로운 스케줄링 시스템을 지원하는 메서드 사용
                let userWorkouts = try await workoutRepository.fetchWorkoutsWithSchedule(for: uid)
                self.allWorkouts = userWorkouts
                self.generateWorkoutsByDate(userWorkouts)
                
                // 기간 계산을 위한 추가 WorkoutResult 데이터 로드
                self.loadAdditionalWorkoutHistory()
                
                print("[DEBUG] 새로운 스케줄링 시스템으로 \(userWorkouts.count)개 워크아웃 로드됨")
            } catch {
                print("[ERROR] 워크아웃 가져오기 실패: \(error)")
            }
        }
    }
    
    // Firestore リスナ 설정 함수
    func setupWorkoutHistoryListener() {
        removeListener()
        
        guard let uid = userManager.currentUser?.uid else {
            print("[ERROR] Listener setup failed: User ID not available.")
            return
        }
        
        guard let currentMonth = selectedMonth else {
            print("[ERROR] Listener setup failed: Selected month not available.")
            return
        }
        
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
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("[DEBUG] No documents found in snapshot for \(currentYearMonth).")
                self.updateCompletedWorkouts(from: [])
                return
            }
            
            print("[DEBUG] Received snapshot update with \(documents.count) documents for \(currentYearMonth).")
            
            let results: [WorkoutResult] = documents.compactMap { document -> WorkoutResult? in
                do {
                    var result = try document.data(as: WorkoutResult.self)
                    result.id = document.documentID
                    return result
                } catch {
                    print("[ERROR] Failed to decode workout result document \(document.documentID): \(error)")
                    return nil
                }
            }
            
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
        
        DispatchQueue.main.async {
            self.completedWorkoutsByDate = workoutsByDate
             print("[DEBUG] Updated completed workouts data: \(self.completedWorkoutsByDate.count) dates with results.")
        }
    }
    
    // 월 변경 시 リスナ 재설정
    func onChangeMonth(_ month: Date?) {
        guard let month = month else { return }
        
        print("[DEBUG] Month changed to \(month.formatted(.dateTime.year().month())). Setting up listener...")
        checkAndLoadMoreMonths(for: month)
        setupWorkoutHistoryListener()
        // 새 월의 워크아웃 스케줄 업데이트
        generateWorkoutsByDate(allWorkouts)
    }
    
    // スクロール 시 前後 2개월이 확보되도록 관리
    func checkAndLoadMoreMonths(for monthDate: Date) {
        if let firstIndex = months.firstIndex(of: monthDate),
           firstIndex == 1 {
            loadPreviousMonth()
        }
        
        if let lastIndex = months.firstIndex(of: monthDate),
           lastIndex == months.count - 2 {
            loadNextMonth()
        }
    }
    
    // months배열에 이전 월 추가
    func loadPreviousMonth() {
        if let firstMonth = months.first,
           let prevMonth = calendar.date(byAdding: .month, value: -1, to: firstMonth) {
            months.insert(prevMonth, at: 0)
        }
    }

    // months배열에 다음 월 추가
    func loadNextMonth() {
        if let lastMonth = months.last,
           let nextMonth = calendar.date(byAdding: .month, value: 1, to: lastMonth) {
            months.append(nextMonth)
        }
    }
    
    // 새로운 스케줄링 시스템을 지원하는 날짜별 워크아웃 생성
    private func generateWorkoutsByDate(_ workouts: [Workout]) {
        var workoutsByDate: [String: [Workout]] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // 현재 월의 시작일과 마지막일 계산
        guard let selectedMonth = selectedMonth else { return }
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.start ?? selectedMonth
        let endOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.end ?? selectedMonth
        
        for workout in workouts {
            let schedule = workout.schedule
            
            switch schedule.type {
            case .oneTime:
                // 일회성 워크아웃
                if let workoutDate = schedule.startDate,
                   workoutDate >= startOfMonth && workoutDate <= endOfMonth {
                    let dateString = dateFormatter.string(from: workoutDate)
                    workoutsByDate[dateString, default: []].append(workout)
                }
                
            case .weekly:
                // 매주 반복 워크아웃
                guard let weeklyDays = schedule.weeklyDays,
                      let startDate = schedule.startDate else { continue }
                
                // 총 횟수가 설정된 경우 제한된 개수만 생성
                if let duration = workout.duration,
                   let totalSessions = duration.totalSessions {
                    generateLimitedWeeklyWorkouts(
                        workout: workout,
                        weeklyDays: weeklyDays,
                        startDate: startDate,
                        totalSessions: totalSessions,
                        startOfMonth: startOfMonth,
                        endOfMonth: endOfMonth,
                        workoutsByDate: &workoutsByDate,
                        dateFormatter: dateFormatter
                    )
                } else {
                    // 무제한 반복
                    var currentDate = max(startDate, startOfMonth)
                    
                    while currentDate <= endOfMonth {
                        let weekday = calendar.component(.weekday, from: currentDate)
                        let weekdayString = getWeekdayString(from: weekday)
                        
                        if weeklyDays.contains(weekdayString) {
                            // 기간 체크 (주 단위, 종료 날짜만)
                            if isWorkoutActiveOnDate(workout: workout, date: currentDate) {
                                let dateString = dateFormatter.string(from: currentDate)
                                workoutsByDate[dateString, default: []].append(workout)
                            }
                        }
                        
                        guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
                        currentDate = nextDate
                    }
                }
                
            case .interval:
                // 간격 반복 워크아웃
                guard let intervalDays = schedule.intervalDays,
                      let startDate = schedule.startDate else { continue }
                
                // 총 횟수가 설정된 경우 제한된 개수만 생성
                if let duration = workout.duration,
                   let totalSessions = duration.totalSessions {
                    generateLimitedIntervalWorkouts(
                        workout: workout,
                        intervalDays: intervalDays,
                        startDate: startDate,
                        totalSessions: totalSessions,
                        startOfMonth: startOfMonth,
                        endOfMonth: endOfMonth,
                        workoutsByDate: &workoutsByDate,
                        dateFormatter: dateFormatter
                    )
                } else {
                    // 무제한 반복
                    var currentDate = startDate
                    
                    while currentDate <= endOfMonth {
                        if currentDate >= startOfMonth && currentDate <= endOfMonth {
                            // 기간 체크 (주 단위, 종료 날짜만)
                            if isWorkoutActiveOnDate(workout: workout, date: currentDate) {
                                let dateString = dateFormatter.string(from: currentDate)
                                workoutsByDate[dateString, default: []].append(workout)
                            }
                        }
                        
                        guard let nextDate = calendar.date(byAdding: .day, value: intervalDays, to: currentDate) else { break }
                        currentDate = nextDate
                    }
                }
                
            case .specificDates:
                // 특정 날짜 워크아웃
                guard let specificDates = schedule.specificDates else { continue }
                
                for date in specificDates {
                    if date >= startOfMonth && date <= endOfMonth {
                        let dateString = dateFormatter.string(from: date)
                        workoutsByDate[dateString, default: []].append(workout)
                    }
                }
            }
        }
        
        self.workoutsByDate = workoutsByDate
        print("[DEBUG] Generated workouts by date: \(workoutsByDate.count) dates with workouts")
    }
    
    // 제한된 횟수의 주간 반복 워크아웃 생성
    private func generateLimitedWeeklyWorkouts(
        workout: Workout,
        weeklyDays: [String],
        startDate: Date,
        totalSessions: Int,
        startOfMonth: Date,
        endOfMonth: Date,
        workoutsByDate: inout [String: [Workout]],
        dateFormatter: DateFormatter
    ) {
        var generatedCount = 0
        var currentDate = startDate
        
        // 시작일부터 정확히 총 횟수만큼 생성
        while generatedCount < totalSessions {
            let weekday = calendar.component(.weekday, from: currentDate)
            let weekdayString = getWeekdayString(from: weekday)
            
            if weeklyDays.contains(weekdayString) {
                // 현재 월 범위에 있으면 추가
                if currentDate >= startOfMonth && currentDate <= endOfMonth {
                    // 주 단위나 종료 날짜 체크도 함께 수행
                    if isWorkoutActiveOnDateExcludingTotalSessions(workout: workout, date: currentDate) {
                        let dateString = dateFormatter.string(from: currentDate)
                        workoutsByDate[dateString, default: []].append(workout)
                    }
                }
                
                generatedCount += 1
                
                if generatedCount >= totalSessions {
                    break
                }
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
    }
    
    // 제한된 횟수의 간격 반복 워크아웃 생성
    private func generateLimitedIntervalWorkouts(
        workout: Workout,
        intervalDays: Int,
        startDate: Date,
        totalSessions: Int,
        startOfMonth: Date,
        endOfMonth: Date,
        workoutsByDate: inout [String: [Workout]],
        dateFormatter: DateFormatter
    ) {
        var generatedCount = 0
        var currentDate = startDate
        
        while generatedCount < totalSessions {
            // 현재 월 범위에 있으면 추가
            if currentDate >= startOfMonth && currentDate <= endOfMonth {
                // 주 단위나 종료 날짜 체크도 함께 수행
                if isWorkoutActiveOnDateExcludingTotalSessions(workout: workout, date: currentDate) {
                    let dateString = dateFormatter.string(from: currentDate)
                    workoutsByDate[dateString, default: []].append(workout)
                }
            }
            
            generatedCount += 1
            
            if generatedCount >= totalSessions {
                break
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: intervalDays, to: currentDate) else { break }
            currentDate = nextDate
        }
    }
    
    // 워크아웃이 특정 날짜에 활성화되어 있는지 확인 (총 횟수 제외한 기간 체크)
    private func isWorkoutActiveOnDateExcludingTotalSessions(workout: Workout, date: Date) -> Bool {
        guard let duration = workout.duration else { return true }
        
        // 종료 날짜 체크
        if let endDate = duration.endDate {
            return date <= endDate
        }
        
        // 주 단위 기간 체크
        if let weeks = duration.weeks {
            guard let startDate = workout.schedule.startDate else { return false }
            
            guard let calculatedEndDate = calendar.date(byAdding: .weekOfYear, value: weeks, to: startDate) else {
                return false
            }
            
            return date >= startDate && date <= calculatedEndDate
        }
        
        return true
    }

    // 워크아웃이 특정 날짜에 활성화되어 있는지 확인 (기간 체크 포함)
    private func isWorkoutActiveOnDate(workout: Workout, date: Date) -> Bool {
        guard let duration = workout.duration else { return true } // 기간 제한이 없으면 항상 활성
        
        // 종료 날짜 체크
        if let endDate = duration.endDate {
            return date <= endDate
        }
        
        // 주 단위 기간 체크
        if let weeks = duration.weeks {
            guard let startDate = workout.schedule.startDate else { return false }
            
            // 시작일로부터 weeks만큼의 기간 계산
            guard let calculatedEndDate = calendar.date(byAdding: .weekOfYear, value: weeks, to: startDate) else {
                return false
            }
            
            return date >= startDate && date <= calculatedEndDate
        }
        
        // 총 횟수의 경우 더 이상 완료 여부로 판단하지 않음 (위에서 제한된 생성으로 처리)
        // duration이 있지만 어떤 조건도 설정되지 않은 경우 활성
        return true
    }
    
    // 특정 워크아웃의 완료 횟수를 계산하는 메서드
    private func getCompletedWorkoutCount(for workoutId: String?, upToDate date: Date) -> Int {
        guard let workoutId = workoutId else { return 0 }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let targetDateString = dateFormatter.string(from: date)
        
        var count = 0
        
        // 모든 완료된 워크아웃을 순회하면서 해당 워크아웃 ID와 매치되는 것들을 카운트
        for (dateString, results) in completedWorkoutsByDate {
            // 대상 날짜 이전까지만 카운트
            if dateString <= targetDateString {
                for result in results {
                    if result.workoutId == workoutId {
                        count += 1
                    }
                }
            }
        }
        
        return count
    }
    
    // 워크아웃의 진행 상황을 확인하는 메서드 (UI에서 사용 가능)
    func getWorkoutProgress(for workout: Workout) -> (completed: Int, total: Int?)? {
        guard let duration = workout.duration,
              let totalSessions = duration.totalSessions else { return nil }
        
        let completedCount = getCompletedWorkoutCount(for: workout.id, upToDate: Date())
        return (completed: completedCount, total: totalSessions)
    }
    
    // ワークアウトの남은 기간を 계산하는 메서드
    func getRemainingDuration(for workout: Workout) -> String? {
        guard let duration = workout.duration else { return nil }
        
        let now = Date()
        
        if let endDate = duration.endDate {
            if endDate < now {
                return "期限切れ"
            }
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: now, to: endDate)
            
            if let days = components.day {
                if days <= 0 {
                    return "今日まで"
                } else if days == 1 {
                    return "1日残り"
                } else {
                    return "\(days)日残り"
                }
            }
        }
        
        if let weeks = duration.weeks,
           let startDate = workout.schedule.startDate {
            
            guard let calculatedEndDate = calendar.date(byAdding: .weekOfYear, value: weeks, to: startDate) else {
                return nil
            }
            
            if calculatedEndDate < now {
                return "期限切れ"
            }
            
            let components = calendar.dateComponents([.weekOfYear, .day], from: now, to: calculatedEndDate)
            
            if let weeksLeft = components.weekOfYear, weeksLeft > 0 {
                return "\(weeksLeft)週残り"
            } else if let daysLeft = components.day, daysLeft > 0 {
                return "\(daysLeft)日残り"
            } else {
                return "今日まで"
            }
        }
        
        // 총 횟수 기반: 완료 상황에 따른 남은 횟수 표시
        if let totalSessions = duration.totalSessions {
            let completedCount = getCompletedWorkoutCount(for: workout.id, upToDate: now)
            let remaining = totalSessions - completedCount
            
            if remaining <= 0 {
                return "完了"
            } else {
                return "\(remaining)回残り"
            }
        }
        
        return nil
    }
    
    // weekday 숫자를 문자열로 변환 (1: Sunday, 2: Monday, ...)
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
    
    // 특정 날짜의 워크아웃 가져오기 (새로운 메서드)
    func getWorkoutsForDate(_ date: Date) -> [Workout] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        return workoutsByDate[dateString] ?? []
    }
    
    // 기존 호환성을 위한 메서드 (요일 인덱스로 워크아웃 가져오기)
    func getWorkoutsForWeekday(index: Int) -> [Workout] {
        // selectedDate의 주간에서 해당 인덱스의 날짜를 계산
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        
        guard let targetDate = calendar.date(byAdding: .day, value: index, to: startOfWeek) else {
            return []
        }
        
        return getWorkoutsForDate(targetDate)
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
    
    // 특정 날짜에 예정된 워크아웃이 있는지 확인
    func hasScheduledWorkout(on date: Date) -> Bool {
        return !getWorkoutsForDate(date).isEmpty
    }
    
    // 만료된 워크아웃 확인
    func isWorkoutExpired(_ workout: Workout) -> Bool {
        guard let duration = workout.duration else { return false }
        
        if let endDate = duration.endDate {
            return endDate < Date()
        }
        
        // TODO: 총 횟수나 주 단위로 설정된 경우의 만료 체크
        // WorkoutResult 데이터와 비교하여 완료 횟수 확인 필요
        
        return false
    }
    
    // 기간 계산을 위해 필요한 모든 월의 WorkoutResult 데이터를 로드하는 메서드
    private func loadAdditionalWorkoutHistory() {
        guard let uid = userManager.currentUser?.uid else { return }
        
        // totalSessions가 설정된 워크아웃들이 있는지 확인
        let workoutsWithTotalSessions = allWorkouts.filter { $0.duration?.totalSessions != nil }
        
        if workoutsWithTotalSessions.isEmpty {
            return // 총 횟수 기반 워크아웃이 없으면 추가 로드 불필요
        }
        
        // 가장 오래된 워크아웃의 시작 날짜부터 현재까지의 모든 월 데이터 로드
        let oldestStartDate = workoutsWithTotalSessions.compactMap { $0.schedule.startDate }.min() ?? Date()
        let currentDate = Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMM"
        
        var monthsToLoad: Set<String> = []
        var date = oldestStartDate
        
        while date <= currentDate {
            let monthString = dateFormatter.string(from: date)
            monthsToLoad.insert(monthString)
            
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: date) else { break }
            date = nextMonth
        }
        
        // 현재 로드된 월 제외
        if let selectedMonth = selectedMonth {
            let currentMonthString = dateFormatter.string(from: selectedMonth)
            monthsToLoad.remove(currentMonthString)
        }
        
        // 추가로 필요한 월들의 데이터 로드
        for monthString in monthsToLoad {
            loadWorkoutHistoryForMonth(uid: uid, month: monthString)
        }
    }
    
    // 특정 월의 WorkoutResult 데이터를 로드하는 메서드
    private func loadWorkoutHistoryForMonth(uid: String, month: String) {
        let monthCollectionRef = db.collection("Result")
            .document(uid)
            .collection(month)
        
        monthCollectionRef.getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("[ERROR] Failed to load workout history for \(month): \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("[DEBUG] No documents found for month \(month)")
                return
            }
            
            let results: [WorkoutResult] = documents.compactMap { document -> WorkoutResult? in
                do {
                    var result = try document.data(as: WorkoutResult.self)
                    result.id = document.documentID
                    return result
                } catch {
                    print("[ERROR] Failed to decode workout result document \(document.documentID): \(error)")
                    return nil
            }
        }
        
            // 기존 데이터와 병합
            DispatchQueue.main.async {
                self.mergeWorkoutResults(results)
            }
        }
    }
    
    // 새로운 WorkoutResult 데이터를 기존 데이터와 병합하는 메서드
    private func mergeWorkoutResults(_ newResults: [WorkoutResult]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for result in newResults {
            guard let date = result.createdAt?.dateValue() else { continue }
            let dateString = dateFormatter.string(from: date)
            
            // 중복 체크 (같은 ID가 이미 있으면 스킵)
            if let existingResults = completedWorkoutsByDate[dateString],
               existingResults.contains(where: { $0.id == result.id }) {
                continue
            }
            
            completedWorkoutsByDate[dateString, default: []].append(result)
        }
        
        print("[DEBUG] Merged additional workout results. Total dates: \(completedWorkoutsByDate.count)")
        
        // 데이터 병합 후 워크아웃 스케줄 재생성
        generateWorkoutsByDate(allWorkouts)
    }
}
