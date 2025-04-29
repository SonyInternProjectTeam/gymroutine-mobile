//
//  NewCreateWorkoutView.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2025/03/15
//  
//

import SwiftUI

struct CreateWorkoutView: View {
    
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel = CreateWorkoutViewModel()
    private let analyticsService = AnalyticsService.shared
    let columns: [GridItem] = Array(repeating: .init(.flexible()),
                                            count: 3)
    
    var body: some View {
        VStack(spacing: 0) {
            
            headerBox
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    nameBox
                    routineBox
                    notesBox
                    exercisesBox
                }
                .padding()
            }
            .background(Color.gray.opacity(0.1))
            .contentMargins(.top, 16)
            .contentMargins(.bottom, 80)
        }
        .fullScreenCover(isPresented: $viewModel.searchExercisesFlg) {
            ExerciseSearchView(exercisesManager: viewModel)
                .presentationDragIndicator(.visible)
        }
        .overlay(alignment: .bottom) {
            buttonBox
                .background(Color(UIColor.systemGray6))
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            // Log screen view
            analyticsService.logScreenView(screenName: "CreateWorkout")
        }
    }
}

//MARK: views
extension CreateWorkoutView {
    private var headerBox: some View {
        Text("ワークアウト作成")
            .font(.title3.bold())
            .hAlign(.center)
            .padding()
            .background(Color(UIColor.systemGray6))
    }
    
    private var nameBox: some View {
        VStack(alignment: .leading) {
            Text("ワークアウト名")
                .font(.headline)
            
            TextField("入力してください", text: $viewModel.workoutName)
                .fieldBackground()
                .submitLabel(.done)
                .clipped()
                .shadow(radius: 1)
        }
    }
    
    private var routineBox: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ルーティーン化する")
                        .font(.headline)
                    
                    Text("ルーティーン化すると、指定された曜日に毎週設定されます")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $viewModel.isRoutine)
                    .labelsHidden()
                    .tint(.main)
            }
            
            if viewModel.isRoutine {
                LazyVGrid(columns: columns) {
                    ForEach(Weekday.allCases, id: \.self) { day in
                        HStack {
                            Image(systemName: viewModel.selectedDays.contains(day) ? "checkmark" : "plus")
                            
                            Text(day.japanese)
                        }
                        .padding(12)
                        .background(viewModel.selectedDays.contains(day) ? .main : .secondary.opacity(0.2))
                        .clipShape(.rect(cornerRadius: 8))
                        .onTapGesture {
                            withAnimation {
                                viewModel.toggleSelectionWeekDay(for: day)
                            }
                        }
                    }
                }
            }
        }
        .animation(.default, value: viewModel.isRoutine)
    }
    
    private var notesBox: some View {
        VStack(alignment: .leading) {
            Text("メモ")
                .font(.headline)
            
            TextField("追加情報を入力する...", text: $viewModel.notes, axis: .vertical)
                .fieldBackground()
                .submitLabel(.done)
                .clipped()
                .shadow(radius: 1)
        }
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
                    
                    WorkoutExerciseCell(workoutExercise: workoutExercise)
                        .onTapGesture {
                            viewModel.onClickedExerciseSets(index: index)
                            
                            // Log exercise set edit
                            analyticsService.logUserAction(
                                action: "edit_exercise_sets",
                                itemId: workoutExercise.id,
                                itemName: workoutExercise.name,
                                contentType: "workout_creation"
                            )
                        }
                        .overlay(alignment: .topTrailing) {
                            Button(action: {
                                viewModel.removeExercise(workoutExercise)
                                
                                // Log exercise removal
                                analyticsService.logUserAction(
                                    action: "remove_exercise",
                                    itemId: workoutExercise.id,
                                    itemName: workoutExercise.name,
                                    contentType: "workout_creation"
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
            .sheet(isPresented: $viewModel.editExerciseSetsFlg) {
                if let index = viewModel.selectedIndex {
                    EditExerciseSetView(
                        order: (index + 1),
                        workoutExercise: $viewModel.exercises[index])
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
            
            Button {
                viewModel.onClickedAddExerciseButton()
                
                // Log add exercise button tap
                analyticsService.logUserAction(
                    action: "add_exercise_button_tap",
                    contentType: "workout_creation"
                )
            } label: {
                Text("エクササイズを追加する")
                    .font(.headline)
            }
            .buttonStyle(CapsuleButtonStyle(color: .main))
            .padding(.horizontal)
        }
    }
    
    private var buttonBox: some View {
        VStack(spacing: 0) {
            
            Divider()
            
            HStack {
                Button {
                    dismiss()
                    
                    // Log cancel workout creation
                    analyticsService.logUserAction(
                        action: "cancel_workout_creation",
                        contentType: "workout_creation"
                    )
                } label: {
                    Label("キャンセル", systemImage: "xmark")
                }
                .buttonStyle(SecondaryButtonStyle())
                
                
                Button {
                    viewModel.onClickedCreateWorkoutButton() {
                        // Log workout creation
                        analyticsService.logEvent("workout_created", parameters: [
                            "workout_name": viewModel.workoutName,
                            "is_routine": viewModel.isRoutine,
                            "has_notes": !viewModel.notes.isEmpty,
                            "exercise_count": viewModel.exercises.count,
                            "scheduled_days": viewModel.isRoutine ? viewModel.selectedDays.map { $0.rawValue }.joined(separator: ",") : ""
                        ])
                        
                        dismiss()
                    }
                } label: {
                    Label("作成する", systemImage: "plus")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
        }
    }

}

#Preview {
    CreateWorkoutView()
}
