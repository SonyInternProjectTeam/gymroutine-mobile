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
    @ObservedObject var viewModel: WorkoutDetailViewModel
    @State private var workoutDeleted = false // State to track deletion
    private let analyticsService = AnalyticsService.shared

    let weekdayOrder: [(english: String, japanese: String)] = [
        ("Monday", "月"),
        ("Tuesday", "火"),
        ("Wednesday", "水"),
        ("Thursday", "木"),
        ("Friday", "金"),
        ("Saturday", "土"),
        ("Sunday", "日"),
    ]

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
        .navigationTitle("ワークアウト詳細")
        .navigationBarTitleDisplayMode(.inline)
        // Toolbar로 커스텀 구성
        .toolbar {
            // 오른쪽: "編集" 버튼
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isCurrentUser {
                    // Use button to trigger sheet presentation instead of NavigationLink
                    Button("編集") {
                        viewModel.showEditView = true
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.workoutSortFlg, onDismiss: {
            viewModel.saveExercisesToFirestore()
        }) {
            WorkoutSortView()
                .environmentObject(viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.searchExercisesFlg) {
            ExerciseSearchView(exercisesManager: viewModel)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showEditView) {
            WorkoutEditView(
                workout: viewModel.workout,
                workoutDeleted: $workoutDeleted
            )
            .environmentObject(viewModel)
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
        }
        // 앱이 활성화될 때마다 데이터 갱신
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            print("📱 앱이 활성화되어 워크아웃 데이터 갱신")
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
                dismiss() // Dismiss DetailView when workout is deleted
            }
        }
    }
    
    private var workoutInfoBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray)
                    .frame(width: 8)
                
                Text(viewModel.workout.name)
                    .font(.title2.bold())
            }
            
            // Display scheduled days if it's a routine
            if viewModel.workout.isRoutine && !viewModel.workout.scheduledDays.isEmpty {
                HStack {
                    Image(systemName: "repeat.circle.fill")
                    Text("毎週：") // "毎週：" (Weekly:) prefix
                    + Text(
                        weekdayOrder
                            .filter { viewModel.workout.scheduledDays.contains($0.english) }
                            .map { $0.japanese }
                            .joined(separator: ", ")
                    )
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
            HStack {
                Text("エクササイズ")
                    .font(.headline)
                Spacer()
                if viewModel.isCurrentUser {
                    Button(action: {
                        viewModel.workoutSortFlg = true
                    }, label: {
                        Text("並び替え")
                    })
                }
            }
            
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
                    })
                    
                        .onTapGesture {
                            if viewModel.isCurrentUser {
                                viewModel.onClickedExerciseSets(index: index)
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            if viewModel.isCurrentUser {
                                Button(action: {
                                    viewModel.removeExercise(workoutExercise)
                                }, label: {
                                    Image(systemName: "xmark")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .padding(8)
                                        .background(.red)
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
                    } label: {
                        Label("追加する", systemImage: "plus")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button {
                        print("📱 始める 버튼이 클릭되었습니다.")
                        viewModel.startWorkout()
                    } label: {
                        Label("始める", systemImage: "play")
                    }
                    .buttonStyle(PrimaryButtonStyle()) 
                } else {
                    Button {
                        viewModel.saveWorkoutDataToMyWorkouts()
                    } label: {
                        if viewModel.isLoadingSaveWorkout {
                            ProgressView()
                        } else {
                            Label("ワークアウトを保存する", systemImage: "square.and.arrow.down")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isLoadingSaveWorkout)
                }
            }
            .padding()
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutDetailView(viewModel: WorkoutDetailViewModel(workout: Workout.mock))
    }
}
