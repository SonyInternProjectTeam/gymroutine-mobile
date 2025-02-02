//
//  ExerciseSearchView.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2024/11/26.
//

import SwiftUI

struct ExerciseSearchView: View {
    
    @ObservedObject var viewModel = ExerciseSearchViewModel()
    @State var CategorySheet:Bool = false
    
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
    }
    
    private var CategoryView: some View {
        HStack(spacing: 150) {
            Text("カテゴリ")
                .font(.title2)
                .fontWeight(.bold)
            Button {
                CategorySheet = true
            } label: {
                ExercisePartToggle(exercisePart: viewModel.selectedExercisePart)
            }
            .sheet(isPresented: $CategorySheet) {
                ExerciseListView
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
    
    private var ExerciseListView: some View {
        List {
            Button {
                viewModel.selectedExercisePart = nil
                viewModel.searchExercisePart()
                CategorySheet = false
            } label: {
                HStack{
                    Text("ALL")
                        .foregroundStyle(.black)
                    Spacer()
                    if viewModel.selectedExercisePart == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }
            ForEach(ExercisePart.allCases, id: \.self) { Part in
                Button {
                    viewModel.selectedExercisePart = Part
                    viewModel.searchExercisePart()
                    CategorySheet = false
                } label: {
                    HStack{
                        Text(Part.rawValue)
                            .foregroundStyle(.black)
                        Spacer()
                        if viewModel.selectedExercisePart == Part
                        {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseSearchView()
    }
}
