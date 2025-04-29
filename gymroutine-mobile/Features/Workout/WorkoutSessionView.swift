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
    private let analyticsService = AnalyticsService.shared
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
            
            // 뷰 모드 전환 버튼
            HStack {
                Spacer()
                Button(action: { 
                    withAnimation {
                        viewModel.toggleViewMode()
                        // Log view mode change
                        analyticsService.logUserAction(
                            action: "toggle_view_mode",
                            contentType: viewModel.isDetailView ? "detail_view" : "list_view"
                        )
                    }
                }) {
                    HStack {
                        Image(systemName: viewModel.isDetailView ? "list.bullet" : "1.square")
                        Text(viewModel.isDetailView ? "リスト表示" : "詳細表示")
                            .font(.footnote)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .cornerRadius(16)
                }
                .padding(.trailing)
            }
            .padding(.vertical, 4)
            .background(Color(UIColor.systemBackground))
            
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
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
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
                    Text("最小化")
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
                        .foregroundStyle(.red)
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
            Button("終了のみ", role: .destructive) {
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
    
    private var timerBox: some View {
        VStack(spacing: 8) {
            Text("タイム")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(viewModel.minutes)")
                    .font(.system(size: 40, weight: .bold))
                    .contentTransition(.numericText())
                Text(":")
                    .font(.system(size: 40, weight: .bold))
                Text("\(String(format: "%02d", viewModel.seconds))")
                    .font(.system(size: 40, weight: .bold))
                    .contentTransition(.numericText())
            }
            
            // 진행 표시 - 점 대신 진행 바와 체크 표시로 변경
            if viewModel.isDetailView {
                exerciseProgressIndicator
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
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
    
    // 진행 바 너비 계산
    private func getProgressWidth(totalWidth: CGFloat) -> CGFloat {
        // 전체 운동 진행률을 기반으로 너비 계산
        let progress = viewModel.totalWorkoutProgress
        return CGFloat(progress) * totalWidth
    }
    
    // 운동 진행 표시기 - 진행 바와 체크 표시
    private var exerciseProgressIndicator: some View {
        VStack(spacing: 8) {
            // 진행 바
            progressBar
                .padding(.vertical, 4)
            
            // 운동 체크 표시
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(0..<viewModel.exercisesManager.exercises.count, id: \.self) { index in
                            VStack(spacing: 4) {
                                // 체크 표시 또는 숫자
                                if isExerciseCompleted(index: index) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 28, height: 28)
                                        .foregroundStyle(.green)
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(index == viewModel.currentExerciseIndex ? .blue : Color(.systemGray4))
                                            .frame(width: 28, height: 28)
                                        
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                    }
                                }
                                
                                // 운동 이름
                                Text(viewModel.exercisesManager.exercises[index].name)
                                    .font(.caption)
                                    .foregroundStyle(index == viewModel.currentExerciseIndex ? .primary : .secondary)
                                    .lineLimit(1)
                                    .frame(maxWidth: 60)
                            }
                            .id(index)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(index == viewModel.currentExerciseIndex ? Color.blue.opacity(0.1) : Color.clear)
                            .cornerRadius(8)
                            .onTapGesture {
                                withAnimation {
                                    viewModel.currentExerciseIndex = index
                                    viewModel.currentSetIndex = 0
                                    viewModel.stopRestTimer()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .coordinateSpace(name: scrollNamespace)
                .padding(.vertical, 4)
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
    }
    
    // 진행 바 컴포넌트
    private var progressBar: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            ZStack(alignment: .leading) {
                // 배경 바
                Rectangle()
                    .foregroundColor(Color(.systemGray5))
                    .frame(height: 6)
                    .cornerRadius(3)
                
                // 전체 진행 바
                Rectangle()
                    .foregroundColor(.blue)
                    .frame(width: getProgressWidth(totalWidth: totalWidth), height: 6)
                    .cornerRadius(3)
            }
        }
        .frame(height: 10)
        .padding(.horizontal)
        .animation(.easeInOut, value: viewModel.totalWorkoutProgress)
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
    
    // 단일 운동 상세 화면
    private var detailExerciseView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let exercise = viewModel.currentExercise {
                    // 운동 이름
                    Text(exercise.name)
                        .font(.title2.bold())
                        .padding(.top)
                    
                    // 운동 이미지와 진행률
                    exerciseProgressCircle(exercise: exercise)

                    // 휴식 시간 설정
                    restTimeSettingView(exercise: exercise)
                    
                    // 세트 정보
                    VStack(spacing: 0) {
                        HStack {
                            Text("メニュー")
                                .font(.headline)
                                .padding(.vertical, 8)
                            
                            Spacer()
                            
                            // 세트 추가 버튼
                            Button(action: {
                                viewModel.addSetToCurrentExercise()
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                    Text("セット追加")
                                        .font(.subheadline)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal)
                        
                        Divider()
                        
                        // 세트 헤더 (중앙 정렬)
                        HStack {
                            Text("セット")
                                .frame(width: 50)
                            Text("kg")
                                .frame(width: 70)
                            Text("レップ数")
                                .frame(width: 70)
                            Text("操作")
                                .frame(width: 80)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        
                        // 세트 목록 (중앙 정렬)
                        ForEach(Array(exercise.sets.enumerated()), id: \.offset) { setIndex, set in
                            HStack {
                                Text("\(setIndex + 1)")
                                    .frame(width: 50)
                                
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
                                .frame(width: 70)
                                
                                // 렙수 표시
                                Text("\(set.reps)")
                                    .frame(width: 70)
                                
                                // 완료 및 삭제 버튼
                                HStack(spacing: 15) {
                                    // 완료 토글 버튼
                                    Button(action: {
                                        viewModel.toggleSetCompletion(exerciseIndex: viewModel.currentExerciseIndex, setIndex: setIndex)
                                    }) {
                                        Image(systemName: viewModel.isSetCompleted(exerciseIndex: viewModel.currentExerciseIndex, setIndex: setIndex) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(viewModel.isSetCompleted(exerciseIndex: viewModel.currentExerciseIndex, setIndex: setIndex) ? .green : .secondary)
                                            .font(.title3)
                                    }
                                    
                                    // 세트 삭제 버튼
                                    Button(action: {
                                        viewModel.removeSet(exerciseIndex: viewModel.currentExerciseIndex, setIndex: setIndex)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundStyle(.red.opacity(0.8))
                                            .font(.callout)
                                    }
                                }
                                .frame(width: 80)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(setIndex == viewModel.currentSetIndex ? Color.blue.opacity(0.1) : Color.clear)
                            
                            if setIndex < exercise.sets.count - 1 {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .background(Color(UIColor.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                } else {
                    Text("エクササイズがありません")
                        .foregroundStyle(.secondary)
                        .padding(.top, 100)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // 모든 운동 리스트 화면
    private var listExercisesView: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(viewModel.exercisesManager.exercises.enumerated()), id: \.element.id) { index, exercise in
                        exerciseCard(exercise: exercise, index: index)
                            .id(index)
                            .opacity(viewModel.currentExerciseIndex == index ? 1.0 : 0.7)
                            .scaleEffect(viewModel.currentExerciseIndex == index ? 1.0 : 0.98)
                            .onTapGesture {
                                withAnimation {
                                    viewModel.currentExerciseIndex = index
                                    scrollProxy.scrollTo(index, anchor: .center)
                                }
                            }
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.currentExerciseIndex) { newIndex in
                withAnimation {
                    scrollProxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }
    
    private func exerciseCard(exercise: WorkoutExercise, index: Int) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // 순서 표시
                Text("\(index + 1)")
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(width: 24)
                
                // 운동 정보
                HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title2)
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text(exercise.name)
                        .font(.headline)
                }
                
                Spacer()
            }
            .padding()
            
            // 세트 목록
            VStack(spacing: 0) {
                // 헤더
                HStack {
                    Text("セット")
                        .frame(width: 60, alignment: .leading)
                    Text("kg")
                        .frame(width: 60, alignment: .leading)
                    Text("レップ数")
                        .frame(width: 60, alignment: .leading)
                    Text("状態")
                        .frame(width: 60, alignment: .leading)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                
                // 세트 리스트
                ForEach(Array(exercise.sets.enumerated()), id: \.offset) { setIndex, set in
                    HStack {
                        Text("\(setIndex + 1)")
                            .frame(width: 60, alignment: .leading)
                        Text(String(format: "%.1f", set.weight))
                            .frame(width: 60, alignment: .leading)
                        Text("\(set.reps)")
                            .frame(width: 60, alignment: .leading)
                        
                        Button(action: {
                            viewModel.toggleSetCompletion(exerciseIndex: index, setIndex: setIndex)
                        }) {
                            Image(systemName: viewModel.isSetCompleted(exerciseIndex: index, setIndex: setIndex) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(viewModel.isSetCompleted(exerciseIndex: index, setIndex: setIndex) ? .green : .secondary)
                        }
                        .frame(width: 60, alignment: .leading)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    if setIndex < exercise.sets.count - 1 {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
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
    
    private var restTimerOverlay: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                VStack(spacing: 15) {
                    Text("휴식 중...")
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
                            .font(.largeTitle)
                            .bold()
                            .contentTransition(.numericText())
                    }
                    .frame(width: 100, height: 100)
                    
                    HStack(spacing: 20) {
                        Button {
                            viewModel.updateRestTime(seconds: viewModel.restSeconds + 15)
                        } label: {
                            Text("+15s")
                                .font(.caption)
                                .padding(8)
                                .background(Color.blue.opacity(0.2))
                                .clipShape(Circle())
                        }
                        
                        Button {
                            viewModel.stopRestTimer()
                            viewModel.moveToNextSet()
                        } label: {
                            Text("Skip")
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(.blue)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            viewModel.updateRestTime(seconds: max(15, viewModel.restSeconds - 15))
                        } label: {
                            Text("-15s")
                                .font(.caption)
                                .padding(8)
                                .background(Color.blue.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .disabled(viewModel.restSeconds <= 15)
                    }
                }
                .padding(30)
                .background(.ultraThickMaterial)
                .cornerRadius(20)
                .shadow(radius: 10)
                
                Spacer()
            }
            
            Spacer()
        }
        .background(Color.black.opacity(0.4))
        .edgesIgnoringSafeArea(.all)
        .onTapGesture {
            // 배경 탭 시 특별한 동작 없음
        }
    }
    
    // 詳細画面のエクササイズ画像と進行円形インジケーター
    private func exerciseProgressCircle(exercise: WorkoutExercise) -> some View {
        ZStack {
            // 背景の円
            Circle()
                .stroke(lineWidth: 20)
                .opacity(0.2)
                .foregroundColor(.blue)
            
            // 進行円
            Circle()
                .trim(from: 0.0, to: CGFloat(viewModel.currentExerciseProgress))
                .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                .foregroundColor(.blue)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.currentExerciseProgress)
            
            // エクササイズ画像
            ExerciseImageCell(imageName: exercise.name)
                .frame(width: 120, height: 120)
                .scaleEffect(tappedProgress ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: tappedProgress)
        }
        .frame(width: 200, height: 200)
        .padding(.vertical, 20)
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
    
    // 탭 애니메이션을 위한 상태 변수 추가
    @State private var tappedProgress = false
    
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
    
    // 진행 원 애니메이션을 위한 키프레임 애니메이션
    @State private var animateProgress = false
    @State private var anchors: [String: UnitPoint] = [:]
    
    // 휴식 시간 설정 뷰
    private func restTimeSettingView(exercise: WorkoutExercise) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text("休憩時間")
                    .font(.headline)
                Spacer()
                // 실시간 남은 시간 대신 설정된 시간 표시
                Text("\(exercise.restTime ?? 90)秒")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Button(action: {
                selectedExerciseIndex = viewModel.currentExerciseIndex // 현재 인덱스 설정
                showRestTimeSettingsSheet = true
            }) {
                HStack {
                    Image(systemName: "timer")
                        .font(.subheadline)
                    Text("設定変更")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}
