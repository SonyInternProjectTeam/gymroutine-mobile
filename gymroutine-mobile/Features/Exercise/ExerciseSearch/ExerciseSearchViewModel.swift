//
//  ExerciseSearchViewModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/01/31.
//

import Foundation
import FirebaseAuth
import SwiftUI

@MainActor
final class ExerciseSearchViewModel: ObservableObject {
    @Published var recommendedExercises: [Exercise] = []
    @Published var filterExercises: [Exercise] = []
    @Published var hasSearched: Bool = false
    @Published var searchWord: String = ""
    @Published var searchedWord: String = ""    //検索された語句を保持
    @Published var filterExercisePartFlg = false
    @Published var selectedExercisePart: ExercisePart? = nil
    @Published var isLoading = false
    private var service = ExerciseService()
    private let recommendExeciseIds: [String] = ["qO1BfPHJXlHcoRhzh24n","qX8qffKedwHds0qMI44H"]
    
    
    @Published var isBoolmarkOnly: Bool = false

    init() {
        fetchRecommendExercise()
    }
    
    func fetchExercise() {
        guard !(searchWord.isEmpty && selectedExercisePart == nil) else {
            filterExercises = []
            hasSearched = false
            return
        }

        hasSearched = true
        searchedWord = searchWord
        
        Task {
            isLoading = true
            let result = await service.fetchExercises(name: searchWord, part: selectedExercisePart)
            switch result {
            case .success(let exercises):
                self.filterExercises = exercises
            case .failure(let error):
                print("[ERROR] Fetch failed: \(error)")
            }
            isLoading = false
        }
    }
    
    //事前に指定したエクササイズをおすすめとして取得
    func fetchRecommendExercise() {
        Task {
            isLoading = true
            var fetchedExercises: [Exercise] = []
            
            await withTaskGroup(of: Result<Exercise, Error>.self) { group in
                for id in recommendExeciseIds {
                    group.addTask {
                        return await self.service.fetchExerciseById(id: id)
                    }
                }

                for await result in group {
                    switch result {
                    case .success(let exercise):
                        fetchedExercises.append(exercise)
                    case .failure(let error):
                        print("[ERROR] おすすめエクササイズ取得失敗: \(error.localizedDescription)")
                    }
                }
            }

            self.recommendedExercises = fetchedExercises
            isLoading = false
        }
    }
    
    func handleFilterExerisePart(part: ExercisePart) {
        if selectedExercisePart == part {
            selectedExercisePart = nil
            filterExercises = []
        } else {
            selectedExercisePart = part
        }
        fetchExercise()
        filterExercisePartFlg = false
    }
    
    func undoSearchWord() {
        searchWord = searchedWord
    }
}
