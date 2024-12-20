//
//  ExerciseSearchView.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2024/11/26.
//

import SwiftUI

struct ExerciseSearchView: View {
    @ObservedObject var viewModel = ExerciseViewModel()
    var selecttrainOptions : [String] = []
    @State private var searchText = ""
    @State private var contentHeight: CGFloat = 0.0
    
    private let Excercisecolumns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    private let Categorycolumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20){
                ExerciseSearchField(text:$viewModel.searchWord)
                    .onSubmit {
                        viewModel.searchExerciseName(for: viewModel.searchWord)
                    }
                CategoryView
                ExeriseTabView
            }
            .padding([.top, .horizontal], 24)
            .background(.gray.opacity(0.2))
            .onAppear {
                viewModel.fetchAll()
            }
        }
    }
    
    private var CategoryView: some View {
        VStack (alignment: .center, spacing:40){
            VStack(alignment: .leading, spacing: 12) {
                Text("カテゴリ")
                    .fontWeight(.bold)
                    .hAlign(.leading)
                    .font(.title2)
                    .fontWeight(.bold)
                LazyVGrid(columns: Categorycolumns,spacing: 20) {
                    ForEach(ExercisePart.allCases, id: \.self) { part in
                        ExercisePartToggle(flag:viewModel.selectedExerciseParts.contains(part),exercisePart: part)
                            .onTapGesture {
                                viewModel.onTapExercisePartToggle(part: part)
                            }
                    }
                }
            }
        }
    }
    
    
    private var ExeriseTabView: some View {
        VStack (alignment: .center, spacing:40){
            VStack(alignment: .leading, spacing: 12) {
                Text("おすすめ")
                    .fontWeight(.bold)
                    .hAlign(.leading)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            ScrollView {
                LazyVGrid(columns: Excercisecolumns, spacing: 8) {
                    ForEach(viewModel.filterExercises, id: \.self) { exercise in
                        NavigationLink (destination: ExerciseDetailView(exercise: exercise),label: {
                            ExersiceSelectButton(name:exercise.name, option: exercise.part)
                        })
                    }
                }
            }
        }
    }
}



#Preview {
    ExerciseSearchView()
}
