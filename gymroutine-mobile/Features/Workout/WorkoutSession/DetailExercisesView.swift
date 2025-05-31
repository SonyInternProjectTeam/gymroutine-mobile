//
//  ListExercisesView.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2025/05/29
//  
//

import SwiftUI

struct DetailExercisesView: View {
    
    let exercise: WorkoutExercise
    @EnvironmentObject var viewModel: WorkoutSessionViewModel
    private let circularSize = UIScreen.main.bounds.width * 0.5
    
    @Namespace private var scrollNamespace
    @State private var tappedProgress = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                GeometryReader { proxy in
                    let minY = -(proxy.frame(in: .named("SCROLL")).minY)
                    
                    VStack(spacing: 0) {
                        exerciseProgressIndicator
                        exerciseTitleBox
                        exerciseProgressCircle
                            .padding(.top)
                    }
                    .offset(y: minY)
                }
                .frame(height: UIScreen.main.bounds.height * 0.35)

                exerciseSetsBox
            }
        }
        .coordinateSpace(name: "SCROLL")
        .vAlign(.center)
    }
}

extension DetailExercisesView {
    
    private var exerciseSetsBox: some View {
        VStack(spacing: 0) {
            VStack {
                HStack {
                    Text("メニュー")
                        .font(.title2.bold())
                    
                    Spacer()
                    
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
                .padding()
                
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
            }
            .padding()
            
            ForEach(
                Array(exercise.sets.enumerated()),
                id: \.element.id)
            { setIndex, set in
                ExerciseSetCell(
                    index: setIndex + 1,
                    isCurrentIndex: setIndex == viewModel.currentSetIndex,
                    isCompleted: viewModel.isSetCompleted(exerciseIndex: viewModel.currentExerciseIndex, setIndex: setIndex),
                    exerciseSet: set,
                    onToggle: {
                        withAnimation {
                            viewModel.toggleSetCompletion(
                                exerciseIndex: viewModel.currentExerciseIndex,
                                setIndex: setIndex
                            )
                        }
                    },
                    onDeleted: {
                        withAnimation {
                            viewModel.removeSet(
                                exerciseIndex: viewModel.currentExerciseIndex,
                                setIndex: setIndex
                            )
                        }
                    }
                )
                .onTapGesture {
                    viewModel.showEditSetInfo(exerciseIndex: viewModel.currentExerciseIndex, setIndex: setIndex)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top),
                    removal: .move(edge: .leading).combined(with: .scale(scale: 0, anchor: .topLeading)).combined(with: .opacity)
                ))
            }
        }
        .padding(.bottom, 156)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 36,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 36
            )
            .fill(.white)
            .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1.5)
        )
    }
    
    // 운동 진행 표시기 - 진행 바와 체크 표시
    private var exerciseProgressIndicator: some View {
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
            }
            .contentMargins(.vertical, 8)
            .contentMargins(.horizontal, 16)
            .coordinateSpace(name: scrollNamespace)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(viewModel.currentExerciseIndex, anchor: .center)
                    }
                }
            }
            .onChange(of: viewModel.currentExerciseIndex) {_, newIndex in
                withAnimation(.easeInOut) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }

    private var exerciseTitleBox: some View {
        HStack(spacing: 16) {
            Rectangle()
                .cornerRadius(4)
                .frame(width: 8, height: 32)
                .foregroundStyle(Color(.systemGray5))

            Text(exercise.name)
                .font(.title2.bold())

            Spacer()

            restTimeSettingView
        }
        .padding(.horizontal, 24)
    }

    // 詳細画面のエクササイズ画像と進行円形インジケーター
    private var exerciseProgressCircle: some View {
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
        .frame(width: circularSize, height: circularSize)
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
    
    // 休憩モーダルの表示
    private var restTimeSettingView: some View {
            Button(action: {
                viewModel.restTimeTargetIndex = viewModel.currentExerciseIndex
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
