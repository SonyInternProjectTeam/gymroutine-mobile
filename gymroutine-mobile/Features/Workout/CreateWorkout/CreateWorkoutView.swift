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
        NavigationView {
            VStack {
                Form {
                    nameBox
                    
                    notesBox
                    
                    scheduleBox
                    
                    if viewModel.hasDuration {
                        durationBox
                    }
                    
                    exercisesSection
                }
                
                createButton
            }
            .navigationTitle("ワークアウト作成")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.searchExercisesFlg) {
            ExerciseSearchView(exercisesManager: viewModel)
        }
        .onAppear {
            // Log screen view
            analyticsService.logScreenView(screenName: "CreateWorkout")
        }
    }
}

//MARK: views
extension CreateWorkoutView {
    private var nameBox: some View {
        VStack(alignment: .leading) {
            Text("ワークアウトの名前")
                .font(.headline)
            
            TextField("ワークアウトの名前を入力してください", text: $viewModel.workoutName)
                .fieldBackground()
                .submitLabel(.done)
                .clipped()
                .shadow(radius: 1)
        }
    }
    
    private var scheduleBox: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("スケジュールの設定")
                .font(.headline)
            
            // スケジュールの種類の選択
            VStack(alignment: .leading, spacing: 12) {
                Text("スケジュールの種類")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(WorkoutScheduleType.allCases, id: \.self) { type in
                        HStack {
                            Image(systemName: viewModel.scheduleType == type ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(viewModel.scheduleType == type ? .main : .secondary)
                            Text(type.displayName)
                                .font(.caption)
                        }
                        .padding(8)
                        .background(viewModel.scheduleType == type ? .main.opacity(0.1) : .secondary.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 8))
                        .onTapGesture {
                            withAnimation {
                                viewModel.scheduleType = type
                            }
                        }
                    }
                }
            }
            
            // スケジュールの種類ごとの設定
            switch viewModel.scheduleType {
            case .oneTime:
                VStack(alignment: .leading, spacing: 8) {
                    Text("実行日")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    DatePicker("", selection: $viewModel.startDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                
            case .weekly:
                VStack(alignment: .leading, spacing: 8) {
                    Text("開始日")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    DatePicker("", selection: $viewModel.startDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    
                    Text("繰り返し日")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    LazyVGrid(columns: columns) {
                        ForEach(Weekday.allCases, id: \.self) { day in
                            HStack {
                                Image(systemName: viewModel.selectedDays.contains(day) ? "checkmark" : "plus")
                                
                                Text(day.japanese)
                                    .font(.caption)
                            }
                            .padding(8)
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
                
            case .interval:
                VStack(alignment: .leading, spacing: 8) {
                    Text("開始日")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    DatePicker("", selection: $viewModel.startDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    
                    HStack {
                        Text("繰り返し間隔")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Stepper(value: $viewModel.intervalDays, in: 1...30) {
                            Text("\(viewModel.intervalDays)日ごとに")
                                .font(.subheadline)
                        }
                    }
                }
                
            case .specificDates:
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("特定の日付")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.addSpecificDate()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.main)
                        }
                    }
                    
                    ForEach(Array(viewModel.specificDates.enumerated()), id: \.offset) { index, date in
                        HStack {
                            DatePicker("", selection: Binding(
                                get: { viewModel.specificDates[index] },
                                set: { viewModel.specificDates[index] = $0 }
                            ), displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            
                            Button(action: {
                                viewModel.removeSpecificDate(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
        }
        .animation(.default, value: viewModel.scheduleType)
    }
    
    private var durationBox: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("期間の制限")
                        .font(.headline)
                    
                    Text("ワークアウトの継続期間を設定できます")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $viewModel.hasDuration)
                    .labelsHidden()
                    .tint(.main)
            }
            
            if viewModel.hasDuration {
                VStack(alignment: .leading, spacing: 12) {
                    // 期間の種類の選択
                    HStack(spacing: 8) {
                        ForEach(CreateWorkoutViewModel.DurationType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: viewModel.durationType == type ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(viewModel.durationType == type ? .main : .secondary)
                                Text(type.displayName)
                                    .font(.caption)
                            }
                            .padding(8)
                            .background(viewModel.durationType == type ? .main.opacity(0.1) : .secondary.opacity(0.1))
                            .clipShape(.rect(cornerRadius: 8))
                            .onTapGesture {
                                withAnimation {
                                    viewModel.durationType = type
                                }
                            }
                        }
                    }
                    
                    // 期間の種類ごとの設定
                    switch viewModel.durationType {
                    case .sessions:
                        HStack {
                            Text("総回数")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Stepper(value: $viewModel.durationTotalSessions, in: 1...100) {
                                Text("\(viewModel.durationTotalSessions)回")
                                    .font(.subheadline)
                            }
                        }
                        
                    case .weeks:
                        HStack {
                            Text("継続期間")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Stepper(value: $viewModel.durationWeeks, in: 1...52) {
                                Text("\(viewModel.durationWeeks)週")
                                    .font(.subheadline)
                            }
                        }
                        
                    case .endDate:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("終了日")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            DatePicker("", selection: $viewModel.durationEndDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                    }
                }
            }
        }
        .animation(.default, value: viewModel.hasDuration)
    }
    
    private var notesBox: some View {
        VStack(alignment: .leading) {
            Text("メモ")
                .font(.headline)
            
            TextField(
                "メモを入力してください...",
                text: $viewModel.notes,
                axis: .vertical
            )
            .submitLabel(.done)
            .frame(maxHeight: 248)
            .padding(12)
            .background(Color(UIColor.systemGray6))
            .clipShape(.rect(cornerRadius: 10))
            .clipped()
            .shadow(radius: 1)
        }
    }
    
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("運動の種類")
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
                                    .background(.red)
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
                Text("運動の種類を追加")
                    .font(.headline)
            }
            .buttonStyle(CapsuleButtonStyle(color: .main))
            .padding(.horizontal)
        }
    }
    
    private var createButton: some View {
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
                            "schedule_type": viewModel.scheduleType.rawValue,
                            "has_duration": viewModel.hasDuration,
                            "has_notes": !viewModel.notes.isEmpty,
                            "exercise_count": viewModel.exercises.count
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
