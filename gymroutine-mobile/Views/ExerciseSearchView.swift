//
//  ExerciseSearchView.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2024/11/26.
//

import SwiftUI

struct ExerciseSearchView: View {

    @ObservedObject var viewModel = ExerciseViewModel()

    private let Categorycolumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible())
    ]

    private let Excercisecolumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ExerciseSearchField(text:$viewModel.searchWord)
                    .onSubmit {
                        viewModel.searchExerciseName(for: viewModel.searchWord)
                    }

                CategoryView

                ExerciseGridView
            }
        }
        .padding([.top, .horizontal], 24)
        .background(.gray.opacity(0.03))
        .onAppear {
            viewModel.fetchAll()
        }
    }

    private var CategoryView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("カテゴリ")
                .font(.title2)
                .fontWeight(.bold)

            LazyVGrid(columns: Categorycolumns,spacing: 16) {
                ForEach(ExercisePart.allCases, id: \.self) { part in
                    Button {
                        viewModel.onTapExercisePartToggle(part: part)
                    } label: {
                        ExercisePartToggle(flag:viewModel.selectedExerciseParts.contains(part),
                                           exercisePart: part)
                    }
                }
            }
        }
    }

    private var ExerciseGridView: some View {
        VStack (alignment: .leading, spacing: 16) {
            Text("おすすめ")
                .font(.title2)
                .fontWeight(.bold)

            LazyVGrid(columns: Excercisecolumns, spacing: 12) {
                ForEach(viewModel.filterExercises, id: \.self) { exercise in
                    NavigationLink (destination: ExerciseDetailView(exercise: exercise), label: {
                        ExersiceSelectButton(exercise: exercise)
                    })
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseSearchView()
    }
}
