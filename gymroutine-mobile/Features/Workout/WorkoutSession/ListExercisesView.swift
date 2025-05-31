//
//  ListExercisesView.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2025/05/30
//  
//

import SwiftUI

struct ListExercisesView: View {
    
    @EnvironmentObject var viewModel: WorkoutSessionViewModel
    
    var body: some View {
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
                            },
                            onEditSet: { setIndex in
                                viewModel.showEditSetInfo(exerciseIndex: viewModel.currentExerciseIndex, setIndex: setIndex)
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
            .contentMargins(.bottom, 156)
            .onChange(of: viewModel.currentExerciseIndex) {_, newIndex in
                withAnimation {
                    scrollProxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
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
}


#Preview {
    let viewModel = WorkoutSessionViewModel(workout: Workout(
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
    ))
    
    ListExercisesView()
        .environmentObject(viewModel)
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
    var onEditSet: ((Int) -> Void)

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
                .padding(.horizontal, 12)

                if isExpanded {
                    VStack(spacing: 12) {
                        HStack {
                            Text("メニュー")
                                .fontWeight(.semibold)

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
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.white)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal)

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
                                    .contentShape(.rect)
                                    .onTapGesture {
                                        onEditSet(setIndex)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
            .background(Color.white)
            .clipShape(.rect(cornerRadius: 8))
            .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1.5)
        }
    }
}
