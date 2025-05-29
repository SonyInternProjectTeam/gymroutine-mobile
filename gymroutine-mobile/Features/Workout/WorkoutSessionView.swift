//
//  WorkoutSessionView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/04/03.
//

import SwiftUI

// 스크롤 위치 추적을 위한 PreferenceKey
struct ViewOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct WorkoutSessionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: WorkoutSessionViewModel
    @Namespace private var scrollNamespace
    @State private var showRestTimeSettingsSheet = false
    @State private var selectedExerciseIndex = 0
    @State private var showEndWorkoutAlert = false // 종료 알림을 위해 필요
    @State private var showEditSetSheet = false
    
    // Analytics Service
    private let analyticsService = AnalyticsService.shared

    // 진행 원 애니메이션을 위한 키프레임 애니메이션
    @State private var animateProgress = false
    @State private var anchors: [String: UnitPoint] = [:]

    // 탭 애니메이션을 위한 상태 변수 추가
    @State private var tappedProgress = false
    @State private var isTimerPaused = false // 타이머 일시정지 상태
    var onEndWorkout: (() -> Void)? = nil // 워크아웃 종료 콜백
    
    init(viewModel: WorkoutSessionViewModel, onEndWorkout: (() -> Void)? = nil) {
        print("📱 WorkoutSessionView 초기화됨")
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onEndWorkout = onEndWorkout
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 타이머 영역
            timerBox
            
            // 운동 영역 (상세 보기 또는 리스트 보기)
            if viewModel.isDetailView {
                detailExerciseView
                    .transition(.opacity)
            } else {
                listExercisesView
                    .transition(.opacity)
            }

            // 하단 네비게이션
            bottomNavigationBox
        }
        .background(.mainBackground)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.white, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { 
                    // 모달 닫기 - 워크아웃은 계속 진행
                    dismiss() 
                    // Log minimize action
                    analyticsService.logUserAction(
                        action: "minimize_workout_session",
                        contentType: "workout_session"
                    )
                }) {
                    Image(systemName: "chevron.down")
                        .foregroundStyle(.blue)
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("ワークアウト")
                    .font(.headline)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // 워크아웃 종료 알림창 표시
                    showEndWorkoutAlert = true
                    // Log end workout button tap
                    analyticsService.logUserAction(
                        action: "end_workout_button_tap",
                        contentType: "workout_session"
                    )
                }) {
                    Text("終了")
                        .foregroundStyle(.blue)
                }
            }
        }
        .overlay {
            if viewModel.isRestTimerActive {
                restTimerOverlay
                    .transition(.opacity)
            }
        }
        .alert("ワークアウト完了", isPresented: $viewModel.showCompletionAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("完了") {
                viewModel.confirmWorkoutCompletion()
                // Log workout completion confirmation
                let workout = viewModel.workout
                let elapsedTime = Date().timeIntervalSince(viewModel.startTime)
                analyticsService.logWorkoutCompleted(
                    workoutId: workout.id ?? "",
                    workoutName: workout.name,
                    duration: elapsedTime,
                    completedExercises: viewModel.exercisesManager.exercises.count
                )
            }
        } message: {
            Text("ワークアウトを完了しますか？")
        }
        // 워크아웃 종료 알림 추가
        .alert("ワークアウトを終了", isPresented: $showEndWorkoutAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("破棄", role: .destructive) {
                // 그냥 종료
                onEndWorkout?()
                dismiss()
                // Log workout exit without saving
                analyticsService.logUserAction(
                    action: "workout_exit_without_saving",
                    contentType: "workout_session"
                )
            }
            Button("結果を保存", role: .none) {
                // 결과 저장 후 종료
                saveAndEndWorkout()
            }
        } message: {
            Text("ワークアウト結果を保存しますか？")
        }
        .animation(.easeInOut, value: viewModel.isRestTimerActive)
        .animation(.easeInOut, value: viewModel.isDetailView)
        .animation(.easeInOut, value: viewModel.currentExerciseIndex)
        .animation(.easeInOut, value: viewModel.currentSetIndex)
        .sheet(isPresented: $viewModel.showAddExerciseSheet) {
            ExerciseSearchView(exercisesManager: viewModel.exercisesManager)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showEditSetSheet) {
            if let editingSet = viewModel.editingSetInfo {
                EditSetView(
                    weight: editingSet.weight,
                    reps: editingSet.reps,
                    onSave: { weight, reps in
                        viewModel.updateSetInfo(weight: weight, reps: reps)
                        // Log set update event
                        if let exercise = viewModel.currentExercise {
                            analyticsService.logUserAction(
                                action: "update_set_info",
                                itemId: exercise.id,
                                itemName: exercise.name,
                                contentType: "exercise_set"
                            )
                        }
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showRestTimeSettingsSheet) {
            if selectedExerciseIndex < viewModel.exercisesManager.exercises.count {
                RestTimeSettingsView(
                    workoutExercise: viewModel.bindingForExercise(at: selectedExerciseIndex),
                    onSave: {
                        // 휴식 시간이 업데이트된 후 명시적으로 Firebase에 저장
                        guard selectedExerciseIndex < viewModel.exercisesManager.exercises.count else { return }
                        let updatedExercise = viewModel.exercisesManager.exercises[selectedExerciseIndex]
                        print("휴식 시간 업데이트: \(updatedExercise.name)의 휴식 시간이 \(updatedExercise.restTime ?? 90)초로 설정됨")
                        
                        // 명시적으로 저장 함수 호출
                        viewModel.saveWorkoutExercises()
                        
                        // UI 업데이트를 위해 현재 운동의 휴게시간 갱신
                        if selectedExerciseIndex == viewModel.currentExerciseIndex {
                            viewModel.updateRestTimeFromCurrentExercise()
                        }
                        
                        // Log rest time update
                        analyticsService.logUserAction(
                            action: "update_rest_time",
                            itemId: updatedExercise.id,
                            itemName: updatedExercise.name,
                            contentType: "exercise_rest_time"
                        )
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            // Log screen view event when workout session appears
            analyticsService.logScreenView(screenName: "WorkoutSession")
            
            // Log workout started event
            let workout = viewModel.workout
            analyticsService.logWorkoutStarted(
                workoutId: workout.id ?? "",
                workoutName: workout.name,
                isRoutine: workout.isRoutine,
                exerciseCount: viewModel.exercisesManager.exercises.count
            )
        }
    }

    // MARK: - [Section1]: TimerBox
    private var timerBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("タイム")
                        .font(.system(size: 16, weight: .semibold))

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(viewModel.minutes)")
                            .contentTransition(.numericText())
                        Text(":")
                        Text("\(String(format: "%02d", viewModel.seconds))")
                            .contentTransition(.numericText())
                    }
                    .font(Font(UIFont.monospacedDigitSystemFont(ofSize: 48, weight: .semibold)))
                }

                Spacer()

                // 타이머 일시정지/재생 버튼
                Button {
                    isTimerPaused.toggle()
                    if isTimerPaused {
                        viewModel.pauseTimer()
                    } else {
                        viewModel.resumeTimer()
                    }
                } label: {
                    Image(systemName: isTimerPaused ? "play.circle.fill" : "pause.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .foregroundStyle(.black)
                }
                .padding(.trailing, 8)

                Button {
                    viewModel.toggleViewMode()
                } label: {
                    Image(systemName: "list.bullet.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .foregroundStyle(.black, .main.opacity(viewModel.isDetailView ? 0 : 1.0))
                }
            }
            .padding(.top, 16)

            Rectangle()
                .frame(height: 2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .animation(.default, value: viewModel.minutes)
        .animation(.default, value: viewModel.seconds)
        .onTapGesture {
            // 타이머 영역 탭 시 현재 세트 완료 처리
            if let exercise = viewModel.currentExercise, viewModel.currentSetIndex < exercise.sets.count {
                viewModel.toggleSetCompletion(
                    exerciseIndex: viewModel.currentExerciseIndex,
                    setIndex: viewModel.currentSetIndex
                )
            }
        }
    }

    // MARK: - [Section2-1]: detailExerciseView
    // 단일 운동 상세 화면
    private var detailExerciseView: some View {
        Group {
            if let exercise = viewModel.currentExercise {
                VStack(spacing: 0) {
                    exerciseProgressIndicator

                    // 운동 이름
                    VStack(spacing: 16) {
                        exerciseTitleBox(exercise: exercise)

                        // 운동 이미지와 진행률
                        exerciseProgressCircle(exercise: exercise)

                        exerciseSetsSection(for: exercise)
                    }
                }
            } else {
                Text("エクササイズがありません")
                    .foregroundStyle(.secondary)
                    .padding(.top, 100)
            }
        }
        .vAlign(.top)
    }

    // 운동 진행 표시기 - 진행 바와 체크 표시
    private var exerciseProgressIndicator: some View {
            // 운동 체크 표시
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<viewModel.exercisesManager.exercises.count, id: \.self) { index in
                        let isCurrentIndex = index == viewModel.currentExerciseIndex
                        let isCompleted = isExerciseCompleted(index: index)

                        Circle()
                            .fill(isCurrentIndex || isCompleted ? .main : Color(.systemGray5))
                            .frame(width: isCurrentIndex ? 32 : 16)
                            .overlay {
                                if isCurrentIndex {
                                    Image(systemName: "flame.fill")
                                        .fontWeight(.semibold)
                                }

                            }
                            .id(index)
                            .onTapGesture {
                                withAnimation {
                                    viewModel.currentExerciseIndex = index
                                    viewModel.currentSetIndex = 0
                                    viewModel.stopRestTimer()
                                }
                            }

                        if index != viewModel.exercisesManager.exercises.count - 1 {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(isCompleted ? .main : Color(.systemGray5))
                                .frame(width: 16, height: 4)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 8)
            .coordinateSpace(name: scrollNamespace)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(viewModel.currentExerciseIndex, anchor: .center)
                    }
                }
            }
            .onChange(of: viewModel.currentExerciseIndex) { newIndex in
                withAnimation(.easeInOut) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }

    private func exerciseTitleBox(exercise: WorkoutExercise) -> some View {
        HStack(spacing: 16) {
            Rectangle()
                .cornerRadius(4)
                .frame(width: 8, height: 32)
                .foregroundStyle(Color(.systemGray5))

            Text(exercise.name)
                .font(.title2.bold())

            Spacer()

            restTimeSettingView(exercise: exercise)
        }
        .padding(.horizontal, 24)
    }

    // 詳細画面のエクササイズ画像と進行円形インジケーター
    private func exerciseProgressCircle(exercise: WorkoutExercise) -> some View {
        ZStack {
            // 背景の円
            Circle()
                .fill(Color(.systemGray6))

            Group {
                if let key = exercise.key, let uiImage = UIImage(named: key) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .padding(28)
                } else {
                    Image(systemName: "nosign")
                        .resizable()
                        .foregroundStyle(.gray)
                        .frame(width: 48, height: 48)
                }
            }
            .scaleEffect(tappedProgress ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: tappedProgress)

            // 進行円
            Circle()
                .trim(from: 0.0, to: CGFloat(viewModel.currentExerciseProgress))
                .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                .foregroundColor(.main)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.easeOut, value: viewModel.currentExerciseProgress)
        }
        .frame(width: 230, height: 230)
        .onTapGesture {
            // 탭 애니메이션 효과
            withAnimation {
                tappedProgress = true
            }

            // 진행 원 탭 시 현재 세트 완료 처리
            if viewModel.currentSetIndex < exercise.sets.count {
                let currentSetIndex = viewModel.currentSetIndex

                // 약간의 지연 시간 후에 상태 변경
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.toggleSetCompletion(
                        exerciseIndex: viewModel.currentExerciseIndex,
                        setIndex: currentSetIndex
                    )

                    // 애니메이션 종료
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            tappedProgress = false
                        }
                    }
                }
            }
        }
    }

    // 휴식 시간 설정 뷰
    private func restTimeSettingView(exercise: WorkoutExercise) -> some View {
            Button(action: {
                selectedExerciseIndex = viewModel.currentExerciseIndex // 현재 인덱스 설정
                showRestTimeSettingsSheet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                    Text("休憩\(exercise.restTime ?? 90)秒")
                }
                .font(.subheadline)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(12)
            }
    }

    private func exerciseSetsSection(for exercise: WorkoutExercise) -> some View {
        // 세트 정보
            VStack(spacing: 8) {
                HStack {
                    Text("メニュー")
                        .font(.headline)

                    Spacer()

                    // 세트 추가 버튼
                    Button(action: {
                        viewModel.addSetToCurrentExercise()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("追加")
                                .font(.subheadline)
                                .bold()
                        }
                        .foregroundStyle(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color(.systemGray5)))
                    }
                }
                .padding(.horizontal, 24)

                HStack(spacing: 0) {
                    Text("セット")
                        .hAlign(.center)
                    Text("重さ（kg）")
                        .hAlign(.center)
                    Text("レップ数")
                        .hAlign(.center)
                    Text("状況")
                        .hAlign(.center)
                }
                .font(.caption)

                // 세트 목록 (중앙 정렬)
                List {
                    ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { setIndex, set in
                        HStack(spacing: 0) {
                            Text("\(setIndex + 1)")
                                .hAlign(.center)

                            // 무게 수정 버튼
                            Button(action: {
                                viewModel.showEditSetInfo(exerciseIndex: viewModel.currentExerciseIndex, setIndex: setIndex)
                            }) {
                                HStack(spacing: 4) {
                                    Text(String(format: "%.1f", set.weight))
                                    Image(systemName: "pencil")
                                        .font(.caption2)
                                }
                                .foregroundStyle(viewModel.isSetCompleted(exerciseIndex: viewModel.currentExerciseIndex, setIndex: setIndex) ? .gray : .primary)
                            }
                            .buttonStyle(.plain)
                            .hAlign(.center)

                            // 렙수 표시
                            Text("\(set.reps)")
                                .hAlign(.center)

                            // 완료 및 삭제 버튼
                                // 완료 토글 버튼
                                Button(action: {
                                    viewModel.toggleSetCompletion(exerciseIndex: viewModel.currentExerciseIndex, setIndex: setIndex)
                                }) {
                                    Image(systemName: viewModel.isSetCompleted(exerciseIndex: viewModel.currentExerciseIndex, setIndex: setIndex) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(viewModel.isSetCompleted(exerciseIndex: viewModel.currentExerciseIndex, setIndex: setIndex) ? .green : .secondary)
                                        .font(.title2)
                                }
                                .buttonStyle(.plain)
                            .hAlign(.center)
                        }
                        .listRowBackground(setIndex == viewModel.currentSetIndex ? Color.blue.opacity(0.1) : Color.clear)
                    }
                    .onDelete { (offsets) in
                        if let index: Int = offsets.first {
                            viewModel.removeSet(exerciseIndex: viewModel.currentExerciseIndex, setIndex: index)
                        }
                    }
                    .listRowInsets(EdgeInsets())
                }
                .scrollIndicators(.hidden)
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
        }
        .padding(.top, 16)
        .background(Color.white)
        .clipShape(.rect(
            topLeadingRadius: 24,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 24
        ))
    }

    // MARK: - [Section2-2]: listExercisesView
    // 모든 운동 리스트 화면
    private var listExercisesView: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(viewModel.exercisesManager.exercises.enumerated()), id: \.element.id) { index, exercise in
                        let isCurrentExercise = index == viewModel.currentExerciseIndex
                        let isCompleted = isExerciseCompleted(index: index)

                        WorkoutExerciseCard(
                            workoutExercise: exercise,
                            index: index,
                            isCurrentExercise: isCurrentExercise,
                            currentSetIndex: viewModel.currentSetIndex,
                            isCompleted: isCompleted,
                            onAddClicked: {
                                viewModel.addSetToExercise(at: index)
                            },
                            onToggleSetCompletion: { setIndex in
                                viewModel.toggleSetCompletion(exerciseIndex: index, setIndex: setIndex)
                            },
                            isSetCompleted: { setIndex in
                                viewModel.isSetCompleted(exerciseIndex: index, setIndex: setIndex)
                            }
                        )
                        .id(index)
                        .onTapGesture {
                            withAnimation {
                                viewModel.currentExerciseIndex = index
                                scrollProxy.scrollTo(index, anchor: .center)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
            }
            .onChange(of: viewModel.currentExerciseIndex) { newIndex in
                withAnimation {
                    scrollProxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }

    // MARK: - [Section3]: bottomNavigationBox
    private var bottomNavigationBox: some View {
        HStack {
            Button(action: {
                if viewModel.isDetailView {
                    viewModel.moveToPreviousSet()
                } else {
                    viewModel.previousExercise()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                viewModel.addExercise()
            }) {
                Image(systemName: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(.blue)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Button(action: {
                if viewModel.isDetailView {
                    viewModel.moveToNextSet()
                } else {
                    viewModel.nextExercise()
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - [Section4]: restTimerOverlay
    private var restTimerOverlay: some View {
        VStack(spacing: 16) {
            Text("休憩中...")
                .font(.title2)
                .fontWeight(.bold)

            ZStack {
                Circle()
                    .stroke(lineWidth: 8)
                    .opacity(0.3)
                    .foregroundColor(.gray)

                Circle()
                    .trim(from: 0.0, to: CGFloat(viewModel.remainingRestSeconds) / CGFloat(viewModel.restSeconds))
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.blue)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear, value: viewModel.remainingRestSeconds)

                Text("\(viewModel.remainingRestSeconds)")
                    .font(Font(UIFont.monospacedDigitSystemFont(ofSize: 36, weight: .bold)))
                    .contentTransition(.numericText())
            }
            .frame(width: 100, height: 100)

            HStack(spacing: 20) {
                Button {
                    viewModel.updateRestTime(seconds: max(15, viewModel.restSeconds - 15))
                } label: {
                    Text("-15s")
                        .font(.caption)
                        .padding(12)
                        .background(Color.blue.opacity(0.2))
                        .clipShape(Circle())
                }
                .disabled(viewModel.restSeconds <= 15)

                Button {
                    viewModel.stopRestTimer()
                    viewModel.moveToNextSet()
                } label: {
                    Text("スキップ")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.updateRestTime(seconds: viewModel.restSeconds + 15)
                } label: {
                    Text("+15s")
                        .font(.caption)
                        .padding(12)
                        .background(Color.blue.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 32)
        .background(.ultraThickMaterial)
        .cornerRadius(20)
        .shadow(radius: 10)
        .hAlign(.center)
        .vAlign(.center)
        .background(Color.black.opacity(0.4))
        .edgesIgnoringSafeArea(.all)
        .onTapGesture {
            // 배경 탭 시 특별한 동작 없음
        }
    }

    // MARK: - Functions
    // 진행 바 너비 계산
    private func getProgressWidth(totalWidth: CGFloat) -> CGFloat {
        // 전체 운동 진행률을 기반으로 너비 계산
        let progress = viewModel.totalWorkoutProgress
        return CGFloat(progress) * totalWidth
    }

    // 운동 완료 여부 확인
    private func isExerciseCompleted(index: Int) -> Bool {
        // 해당 운동의 모든 세트가 완료되었는지 확인
        guard index < viewModel.exercisesManager.exercises.count else { return false }
        let exercise = viewModel.exercisesManager.exercises[index]
        if exercise.sets.isEmpty { return true }

        for setIndex in 0..<exercise.sets.count {
            if !viewModel.isSetCompleted(exerciseIndex: index, setIndex: setIndex) {
                return false
            }
        }
        return true
    }

    private func saveAndEndWorkout() {
        // 세션 상태를 저장
        viewModel.saveWorkoutExercises()
        
        // 세션 중 업데이트된 운동 정보로 새 워크아웃 모델 생성
        let updatedWorkout = Workout(
            id: viewModel.workout.id ?? "",
            userId: viewModel.workout.userId ?? "",
            name: viewModel.workout.name,
            createdAt: viewModel.workout.createdAt,
            notes: viewModel.workout.notes,
            isRoutine: viewModel.workout.isRoutine,
            scheduledDays: viewModel.workout.scheduledDays,
            exercises: viewModel.exercisesManager.exercises
        )
        
        let finalElapsedTime = Date().timeIntervalSince(viewModel.startTime)
        let completedSession = WorkoutSessionModel(
            workout: updatedWorkout,  // 업데이트된 워크아웃 정보 사용
            startTime: viewModel.startTime,
            elapsedTime: finalElapsedTime,
            completedSets: viewModel.completedSets,
            totalRestTime: viewModel.getTotalRestTime()
        )
        
        // Log workout completion
        analyticsService.logWorkoutCompleted(
            workoutId: updatedWorkout.id ?? "",
            workoutName: updatedWorkout.name,
            duration: finalElapsedTime,
            completedExercises: viewModel.exercisesManager.exercises.count
        )
        
        // Log exercises completed
        for exercise in viewModel.exercisesManager.exercises {
            let completedSets = exercise.sets.filter { set in 
                let exerciseIndex = viewModel.exercisesManager.exercises.firstIndex(where: { $0.id == exercise.id }) ?? 0
                let setIndex = exercise.sets.firstIndex(where: { $0.id == set.id }) ?? 0
                return viewModel.isSetCompleted(exerciseIndex: exerciseIndex, setIndex: setIndex)
            }.count
            
            let totalReps = exercise.sets.filter { set in
                let exerciseIndex = viewModel.exercisesManager.exercises.firstIndex(where: { $0.id == exercise.id }) ?? 0
                let setIndex = exercise.sets.firstIndex(where: { $0.id == set.id }) ?? 0
                return viewModel.isSetCompleted(exerciseIndex: exerciseIndex, setIndex: setIndex)
            }.reduce(0) { $0 + $1.reps }
            
            let completedSetsWithWeight = exercise.sets.filter { set in
                let exerciseIndex = viewModel.exercisesManager.exercises.firstIndex(where: { $0.id == exercise.id }) ?? 0
                let setIndex = exercise.sets.firstIndex(where: { $0.id == set.id }) ?? 0
                return viewModel.isSetCompleted(exerciseIndex: exerciseIndex, setIndex: setIndex) && set.weight > 0
            }
            
            let averageWeight = completedSetsWithWeight.isEmpty ? 0.0 :
                completedSetsWithWeight.map { $0.weight }.reduce(0.0, +) / Double(completedSetsWithWeight.count)
            
            analyticsService.logExerciseCompleted(
                exerciseName: exercise.name,
                workoutId: updatedWorkout.id ?? "",
                sets: completedSets,
                reps: totalReps,
                weight: averageWeight > 0 ? averageWeight : nil
            )
        }
        
        // AppWorkoutManager의 completeWorkout 호출하여 결과 화면으로 이동
        AppWorkoutManager.shared.completeWorkout(session: completedSession)
        dismiss()
    }
}

fileprivate
struct WorkoutExerciseCard: View {

    @State private var isExpanded: Bool = true
    var workoutExercise: WorkoutExercise
    var index: Int
    var isCurrentExercise: Bool
    var currentSetIndex: Int
    var isCompleted: Bool
    var onAddClicked: (() -> Void)
    var onToggleSetCompletion: ((Int) -> Void)
    var isSetCompleted: ((Int) -> Bool)

    var body: some View {
        HStack {
            VStack {
                Group {
                    if isCurrentExercise {
                        Image(systemName: "flame.fill")
                    } else {
                        Text("\(index + 1)")
                    }
                }
                .fontWeight(.semibold)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isCurrentExercise || isCompleted ? .main : Color(.systemGray5))
                )

                RoundedRectangle(cornerRadius: 4)
                    .fill(isCurrentExercise || isCompleted ? .main : Color(.systemGray5))
                    .frame(width: 4)
            }

            VStack(spacing: 10) {
                // Exercise Info
                HStack(spacing: 16) {
                    ExerciseImageCell(imageName: workoutExercise.key)
                        .frame(width: 56, height: 56)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(workoutExercise.toPartName())
                            .font(.caption)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.secondary.opacity(0.4), lineWidth: 2)
                            )

                        Text(LocalizedStringKey(workoutExercise.name))
                            .font(.headline)
                    }

                    Spacer()

                    Button {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: "chevron.right.circle")
                            .resizable()
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 32)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                }

                if isExpanded {
                    VStack(spacing: 8) {
                        HStack {
                            Text("メニュー")

                            Spacer()

                            Button(action: {
                                onAddClicked()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("追加")
                                        .font(.subheadline)
                                        .bold()
                                }
                                .foregroundStyle(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.white)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                            }
                        }

                        Divider()

                        // Menu Table
                        VStack(spacing: 4) {
                            HStack(spacing: 0) {
                                Text("セット")
                                    .hAlign(.center)
                                Text("重さ（kg）")
                                    .hAlign(.center)
                                Text("レップ数")
                                    .hAlign(.center)
                                Text("状況")
                                    .hAlign(.center)
                            }
                            .font(.caption)

                            VStack(spacing: 0) {
                                ForEach(Array(workoutExercise.sets.enumerated()), id: \.element.id) { setIndex, set in
                                    let isCompleted = isSetCompleted(setIndex)
                                    HStack(spacing: 0) {
                                        Text("\(setIndex + 1)").hAlign(.center)

                                        Text(String(format: "%.1f", set.weight)).hAlign(.center)

                                        Text("\(set.reps)").hAlign(.center)

                                        Button(action: {
                                            onToggleSetCompletion(setIndex)
                                        }) {
                                            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                                .foregroundStyle(isCompleted ? .green : .secondary)
                                        }
                                        .hAlign(.center)
                                    }
                                    .font(.subheadline)
                                    .padding(.vertical, 8)
                                    .background(isCurrentExercise && setIndex == currentSetIndex ? Color.blue.opacity(0.1) : Color.clear)
                                }
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(.systemGray6).cornerRadius(8))
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(.rect(cornerRadius: 8))
            .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1.5)
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutSessionView(viewModel: WorkoutSessionViewModel(workout: Workout(
            id: "1",
            userId: "user123",
            name: "Full Body Workout",
            createdAt: Date(),
            notes: "Focus on compound movements.",
            isRoutine: true,
            scheduledDays: ["Monday", "Wednesday", "Friday"],
            exercises: [
                WorkoutExercise.mock()
            ]
        )))
    }
}
