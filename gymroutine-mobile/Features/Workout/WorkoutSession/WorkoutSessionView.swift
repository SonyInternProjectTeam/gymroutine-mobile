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
    @State private var showEndWorkoutAlert = false // 종료 알림을 위해 필요
    @State private var showEditSetSheet = false
    
    // Analytics Service
    private let analyticsService = AnalyticsService.shared
    
    // 진행 원 애니메이션을 위한 키프레임 애니메이션
    @State private var animateProgress = false
    @State private var anchors: [String: UnitPoint] = [:]
    
    // 탭 애니메이션을 위한 상태 변수 추가
    @State private var tappedProgress = false
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
            
            if let exericse = viewModel.currentExercise {
                if viewModel.isDetailView {
                    DetailExercisesView(exercise: exericse)
                        .environmentObject(viewModel)
                        .transition(.opacity)
                } else {
                    ListExercisesView()
                        .environmentObject(viewModel)
                        .transition(.opacity)
                }
            } else {
                nothingExerciseView
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .safeAreaInset(edge: .bottom) {
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
        .sheet(isPresented: Binding<Bool>(
            get: { viewModel.restTimeTargetIndex != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.restTimeTargetIndex = nil
                }
            })
        ) {
            if let index = viewModel.restTimeTargetIndex,
               index < viewModel.exercisesManager.exercises.count {
                
                RestTimeSettingsView(
                    workoutExercise: viewModel.bindingForExercise(at: index),
                    onSave: {
                        viewModel.updateRestTime(for: index)
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
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(viewModel.minutes)")
                        .contentTransition(.numericText())
                    Text(":")
                    Text("\(String(format: "%02d", viewModel.seconds))")
                        .contentTransition(.numericText())
                }
                .font(Font(UIFont.monospacedDigitSystemFont(ofSize: 48, weight: .semibold)))
                
                Spacer()
                
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
            
            CustomDivider()
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
    
    private var nothingExerciseView: some View {
        VStack(spacing: 16) {
            Image("Side Plank")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
            
            Text("エクササイズを追加しましょう")
                .font(.title2.bold())
            
            Image(systemName: "arrowshape.down.fill")
                .font(.title.bold())
        }
        .opacity(0.4)
        .padding(24)
        .vAlign(.center)
    }

    // MARK: - [Section3]: bottomNavigationBox
    private var bottomNavigationBox: some View {
        HStack(spacing: 36) {
            Button(action: {
                if viewModel.isDetailView {
                    viewModel.moveToPreviousSet()
                } else {
                    viewModel.previousExercise()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2.bold())
            }
            .foregroundStyle(.secondary)
            
            Button(action: {
                viewModel.addExercise()
            }) {
                Image(systemName: "plus")
                    .font(.title2.bold())
            }
            .buttonStyle(CapsuleButtonStyle(color: .main))
            
            Button(action: {
                if viewModel.isDetailView {
                    viewModel.moveToNextSet()
                } else {
                    viewModel.nextExercise()
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2.bold())
            }
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(Color(UIColor.systemBackground))
        .overlay(alignment: .top) {
            CustomDivider()
        }
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
    }
    
    // MARK: - Functions
    
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
