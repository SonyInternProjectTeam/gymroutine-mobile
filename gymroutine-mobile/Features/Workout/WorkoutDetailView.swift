//
//  WorkoutDetailView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/04/01.
//

import SwiftUI

struct WorkoutDetailView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: WorkoutDetailViewModel
    
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
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                    }
                    Text("ワークアウト詳細")
                        .font(.headline)
                }
            }
            // 오른쪽: "編集" 버튼
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("編集") {
                    viewModel.editWorkout()
                }
            }
        }
        .sheet(isPresented: $viewModel.searchExercisesFlg) {
            ExerciseSearchView(exercisesManager: viewModel)
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            // 뷰가 나타날 때마다 최신 데이터를 불러옴
            viewModel.refreshWorkoutData()
        }
    }
    
    private var workoutInfoBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.workout.name)
                .font(.title2.bold())
            
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
                    
                    WorkoutExerciseCell(workoutExercise: workoutExercise)
                        .onTapGesture {
                            viewModel.onClickedExerciseSets(index: index)
                        }
                        .overlay(alignment: .topTrailing) {
                            Button(action: {
                                viewModel.removeExercise(workoutExercise)
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
                    .onDisappear {
                        // 세트 편집 모달이 닫힐 때 변경사항 저장
                        if let index = viewModel.selectedIndex {
                            viewModel.updateExerciseSetAndSave(for: viewModel.exercises[index])
                        }
                    }
                }
            }
        }
    }
    
    private var buttonBox: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Button {
                    viewModel.addExercise()
                } label: {
                    Label("追加する", systemImage: "plus")
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button {
                    viewModel.startWorkout()
                } label: {
                    Label("始める", systemImage: "play")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
        }
    }
}
