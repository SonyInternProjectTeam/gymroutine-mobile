//
//  WorkoutDetailView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/04/01.
//

import SwiftUI

// Add notification name for workout deletion
extension Notification.Name {
    static let workoutDeleted = Notification.Name("workoutDeleted")
}

struct WorkoutDetailView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: WorkoutDetailViewModel
    @State private var workoutDeleted = false // State to track deletion
    private let analyticsService = AnalyticsService.shared
    
    var body: some View {
        // NavigationStack(또는 NavigationView) 내부에서 뷰를 표시
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    workoutInfoBox
                    exercisesBox
                }
                .padding()
            }
            .background(Color.gray.opacity(0.1))
            .contentMargins(.top, 16)
            .contentMargins(.bottom, 80)
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        // 하단 버튼
        .overlay(alignment: .bottom) {
            buttonBox
                .background(Color(UIColor.systemGray6))
        }
        // **기본 백 버튼 숨김 + Inline Title**
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        // Toolbar로 커스텀 구성
        .toolbar {
            // 왼쪽: 커스텀 Back 버튼 + 타이틀
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    Button(action: { 
                        dismiss() 
                        
                        // Log navigate back
                        analyticsService.logUserAction(
                            action: "navigate_back",
                            itemId: viewModel.workout.id ?? "",
                            contentType: "workout_detail"
                        )
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                    }
                    Text("ワークアウト詳細")
                        .font(.headline)
                }
            }
            // 오른쪽: "編集" 버튼
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isCurrentUser {
                    // Use button to trigger sheet presentation instead of NavigationLink
                    Button("編集") {
                        viewModel.showEditView = true
                        
                        // Log edit button tap
                        analyticsService.logUserAction(
                            action: "edit_workout_button_tap",
                            itemId: viewModel.workout.id ?? "",
                            itemName: viewModel.workout.name,
                            contentType: "workout_detail"
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.searchExercisesFlg) {
            ExerciseSearchView(exercisesManager: viewModel)
                .presentationDragIndicator(.visible)
        }
        // 편집 화면 추가
        .sheet(isPresented: $viewModel.showEditView) {
            // 편집 화면이 닫힐 때 워크아웃 데이터 새로고침
            viewModel.refreshWorkoutData()
        } content: {
            NavigationView {
                WorkoutEditView(workout: viewModel.workout, workoutDeleted: $workoutDeleted)
            }
        }
        
        // AppWorkoutManager의 showWorkoutSession 값 변경 감지
        .onChange(of: viewModel.showWorkoutSession) {
            print("📱 showWorkoutSession 값이 변경되었습니다: \(viewModel.showWorkoutSession)")
        }
        .onAppear {
            // 뷰가 나타날 때마다 최신 데이터를 불러옴
            viewModel.refreshWorkoutData()
            
            // Log screen view
            analyticsService.logScreenView(screenName: "WorkoutDetail")
            
            // Log workout detail viewed
            analyticsService.logEvent("workout_detail_viewed", parameters: [
                "workout_id": viewModel.workout.id ?? "",
                "workout_name": viewModel.workout.name,
                "is_routine": viewModel.workout.isRoutine,
                "is_current_user": viewModel.isCurrentUser,
                "exercise_count": viewModel.exercises.count
            ])
        }
        // 앱이 활성화될 때마다 데이터 갱신
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            print("📱 앱이 활성화되어 워크아웃 데이터 갱신")
            viewModel.refreshWorkoutData()
        }
        // 주기적으로 데이터 새로고침 (30초마다)
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in
            print("⏱️ 주기적인 워크아웃 데이터 갱신")
            viewModel.refreshWorkoutData()
        }
        // Detect when deletion happens in EditView
        .onChange(of: workoutDeleted) { deleted in
            if deleted {
                // Post notification when workout is deleted
                NotificationCenter.default.post(
                    name: .workoutDeleted, 
                    object: nil,
                    userInfo: ["workoutId": viewModel.workout.id ?? ""]
                )
                
                // Log workout deletion
                analyticsService.logEvent("workout_deleted", parameters: [
                    "workout_id": viewModel.workout.id ?? "",
                    "workout_name": viewModel.workout.name
                ])
                
                dismiss() // Dismiss DetailView when workout is deleted
            }
        }
    }
    
    private var workoutInfoBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.workout.name)
                .font(.title2.bold())
            
            // Display scheduled days if it's a routine
            if viewModel.workout.isRoutine && !viewModel.workout.scheduledDays.isEmpty {
                HStack {
                    Image(systemName: "repeat.circle.fill")
                    Text("毎週：") // "毎週：" (Weekly:) prefix
                    Text(viewModel.workout.scheduledDays.joined(separator: ", "))
                }
                .font(.caption)
                .foregroundStyle(.blue)
                .padding(.vertical, 4)
            }
            
            if let notes = viewModel.workout.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var exercisesBox: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("エクササイズ")
                .font(.headline)
            
            ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { index, workoutExercise in
                HStack {
                    VStack {
                        Text("\(index + 1)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding()
                            .background(.main)
                            .clipShape(Circle())
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.main)
                            .frame(width: 4)
                    }
                    
                    WorkoutExerciseCell(workoutExercise: workoutExercise, onRestTimeClicked: {
                        viewModel.showRestTimeSettings(for: index)
                        
                        // Log rest time settings tap
                        analyticsService.logUserAction(
                            action: "rest_time_settings_tap",
                            itemId: workoutExercise.id,
                            itemName: workoutExercise.name,
                            contentType: "workout_detail"
                        )
                    })
                    
                        .onTapGesture {
                            if viewModel.isCurrentUser {
                                viewModel.onClickedExerciseSets(index: index)
                                
                                // Log exercise sets edit tap
                                analyticsService.logUserAction(
                                    action: "exercise_sets_edit_tap",
                                    itemId: workoutExercise.id,
                                    itemName: workoutExercise.name,
                                    contentType: "workout_detail"
                                )
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            if viewModel.isCurrentUser {
                                Button(action: {
                                    viewModel.removeExercise(workoutExercise)
                                    
                                    // Log exercise removal
                                    analyticsService.logUserAction(
                                        action: "remove_exercise",
                                        itemId: workoutExercise.id,
                                        itemName: workoutExercise.name,
                                        contentType: "workout_detail"
                                    )
                                }, label: {
                                    Image(systemName: "xmark")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .padding(8)
                                        .background(.red .opacity(0.5))
                                        .clipShape(Circle())
                                        .padding(10)
                                })
                            }
                        }
                }
            }
            .sheet(isPresented: $viewModel.editExerciseSetsFlg) {
                if let index = viewModel.selectedIndex {
                    EditExerciseSetView(
                        order: (index + 1),
                        workoutExercise: $viewModel.exercises[index])
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .onDisappear {
                        // 세트 편집 모달이 닫힐 때 변경사항 저장
                        if let index = viewModel.selectedIndex {
                            viewModel.updateExerciseSetAndSave(for: viewModel.exercises[index])
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showRestTimeSettingsSheet) {
                if let index = viewModel.selectedRestTimeIndex {
                    RestTimeSettingsView(
                        workoutExercise: $viewModel.exercises[index],
                        onSave: {
                            // This will be called after the exercise's rest time is updated
                            viewModel.updateExerciseSetAndSave(for: viewModel.exercises[index])
                        }
                    )
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                }
            }
        }
    }
    
    private var buttonBox: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                if viewModel.isCurrentUser {
                    Button {
                        viewModel.addExercise()
                        
                        // Log add exercise button tap
                        analyticsService.logUserAction(
                            action: "add_exercise_button_tap",
                            itemId: viewModel.workout.id ?? "",
                            contentType: "workout_detail"
                        )
                    } label: {
                        Label("追加する", systemImage: "plus")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button {
                        print("📱 始める 버튼이 클릭되었습니다.")
                        viewModel.startWorkout()
                        
                        // Log start workout button tap
                        analyticsService.logUserAction(
                            action: "start_workout_button_tap",
                            itemId: viewModel.workout.id ?? "",
                            itemName: viewModel.workout.name,
                            contentType: "workout_detail"
                        )
                    } label: {
                        Label("始める", systemImage: "play")
                    }
                    .buttonStyle(PrimaryButtonStyle()) 
                } else {
                    // 다른 사용자의 워크아웃인 경우 메시지 표시
                    Text("他のユーザーのワークアウトは編集できません")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
    }
}
