//
//  NewExerciseSearchView.swift
//  gymroutine-mobile
//
//  Created by SATTSAT on 2025/03/16
//
//

import SwiftUI

struct ExerciseSearchView: View {
    
    @Environment(\.dismiss) private var dismiss
    private let isReadOnly: Bool
    @ObservedObject var exercisesManager: WorkoutExercisesManager
    @StateObject private var viewModel = ExerciseSearchViewModel()
    @FocusState private var isFocused: Bool
    private let exerciseColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible())
    ]
    
    // 呼び出し時にManagerを引数に入れないと、＋ボタンを表示せず読み取り専用になる
    init(exercisesManager: WorkoutExercisesManager? = nil) {
        self.isReadOnly = exercisesManager == nil
        self.exercisesManager = exercisesManager ?? WorkoutExercisesManager()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 36) {
                    searchBox
                    
                    if viewModel.selectedExercisePart != nil || !viewModel.searchWord.isEmpty {
                        filterBox
                    } else {
                        exercisePartBox
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        if viewModel.filterExercises.isEmpty {
                            if viewModel.hasSearched {
                                Text("条件に一致するエクササイズが見つかりません。")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                    .padding(.bottom)

                                if !viewModel.recommendedExercises.isEmpty {
                                    exercisesGridView(
                                        title: "おすすめ",
                                        exercises: viewModel.recommendedExercises
                                    )
                                }

                            } else {
                                if !viewModel.recommendedExercises.isEmpty {
                                    exercisesGridView(
                                        title: "おすすめ",
                                        exercises: viewModel.recommendedExercises
                                    )
                                }
                            }
                        } else {
                            exercisesGridView(
                                title: viewModel.searchedWord.isEmpty ?
                                    "「\(viewModel.selectedExercisePart?.rawValue ?? "")」の絞り込み結果" :
                                    "「\(viewModel.searchedWord)」の検索結果",
                                exercises: viewModel.filterExercises
                            )
                        }
                    }
                }
                .padding()
            }
            .animation(.default, value: viewModel.selectedExercisePart)
            .background(Color.gray.opacity(0.1))
            .sheet(isPresented: $viewModel.filterExercisePartFlg) {
                selectExercisePartView
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    private var searchBox: some View {
        HStack {
            ExerciseSearchField(text: $viewModel.searchWord)
                .submitLabel(.search)
                .focused($isFocused)
                .clipped()
                .shadow(radius: 1)
                .onSubmit { viewModel.fetchExercise() }
                .overlay(alignment: .trailing) {
                    if !viewModel.searchWord.isEmpty && isFocused {
                        Button(action: {
                            viewModel.searchWord = ""
                        }, label: {
                            Image(systemName: "xmark.circle.fill")
                        })
                        .padding(.trailing, 8)
                    }
                }
            
            if isFocused {
                Button("キャンセル") {
                    isFocused = false
                    viewModel.undoSearchWord()
                }
            } else {
                Button(action: {
                    dismiss()
                }, label: {
                    Image(systemName: "xmark")
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding(10)
                        .background(.main)
                        .clipShape(Circle())
                })
                .foregroundStyle(.white)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
    
    private var exercisePartBox: some View {
        LazyVGrid(columns: exerciseColumns, spacing: 12) {
            ForEach(ExercisePart.allCases, id: \.self) { part in
                exercisePartCell(part)
            }
        }
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private func exercisePartCell(_ part: ExercisePart) -> some View {
        Button(action: {
            viewModel.handleFilterExerisePart(part: part)
        }) {
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey(part.rawValue))
                    .font(.headline)
                
                if let image = UIImage(named: part.rawValue) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 65)
                        .hAlign(.trailing)
                }
            }
            .hAlign(.leading)
            .padding(10)
            .background(
                RadialGradient(gradient: Gradient(colors: [.white, .main]), center: .bottomTrailing, startRadius: 1, endRadius: 160)
            )
            .clipShape(.rect(cornerRadius: 8))
            .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1.5)
        }
        .foregroundStyle(.black)
    }
    
    private var filterBox: some View {
        HStack {
            //            Toggle(isOn: $viewModel.isBoolmarkOnly) {
            //                Text("ブックマークのみ")
            //                    .font(.body)
            //            }
            //            .tint(.main)
            //            .toggleStyle(.checkBox)
            //            .hAlign(.leading)
            Spacer()
            
            Button {
                viewModel.filterExercisePartFlg = true
            } label: {
                Group {
                    if let part = viewModel.selectedExercisePart {
                        Label(LocalizedStringKey(part.rawValue), systemImage: "slider.horizontal.3")
                            .foregroundStyle(.main)
                    } else {
                        Label("絞り込み", systemImage: "slider.horizontal.3")
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal)
                .background(Color(UIColor.systemGray6))
                .clipShape(Capsule())
                .shadow(radius: 1)
            }
            .foregroundStyle(.primary)
        }
    }
    
    private var selectExercisePartView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                HStack {
                    Text("部位を選択")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let part = viewModel.selectedExercisePart {
                        Button(action: {
                            viewModel.handleFilterExerisePart(part: part)
                        }, label: {
                            Text("クリア")
                        })
                    }
                }
                
                LazyVGrid(columns: exerciseColumns, spacing: 12) {
                    ForEach(ExercisePart.allCases, id: \.self) { part in
                        Button(action: {
                            viewModel.handleFilterExerisePart(part: part)
                        }) {
                            Text(LocalizedStringKey(part.rawValue))
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            viewModel.selectedExercisePart == part ? Color.main : Color.secondary,
                                            lineWidth: 2)
                                )
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.gray.opacity(0.1))
        .contentMargins(.top, 24)
    }
    
    @ViewBuilder
    private func exercisesGridView(title: String, exercises: [Exercise]) -> some View {
        VStack (alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: exerciseColumns, spacing: 12) {
                ForEach(exercises, id: \.self) { exercise in
                    NavigationLink {
                        ExerciseDetailView(
                            exercise: exercise,
                            isReadOnly: isReadOnly,
                            onAddButtonTapped: {
                                exercisesManager.appendExercise(exercise: exercise)
                                dismiss()
                            }
                        )
                    } label: {
                        ExerciseGridCell(
                            exercise: exercise,
                            isReadOnly: isReadOnly,
                            onTapPlusButton: {
                                exercisesManager.appendExercise(exercise: exercise)
                                dismiss()
                            })
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

#Preview {
    ExerciseSearchView()
}
