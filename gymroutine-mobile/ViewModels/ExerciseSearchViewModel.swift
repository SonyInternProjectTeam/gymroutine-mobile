//
//  ExerciseSearchViewModel.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2024/12/06.
//

import Foundation
import FirebaseAuth

class ExerciseSearchViewModel: ObservableObject {
    @Published var trainOptions: [String] = []
    @Published var allExercises: [Exercise] = []
    @Published var filterExercises: [Exercise] = []
    @Published var searchWord: String = ""
    @Published var selectedExerciseParts: [ExercisePart] = []
    @Published var selectedExercisePart: ExercisePart? = nil
    private var service = ExerciseService()
    
    init() {
        fetchAll()
    }
    
    func fetchAll() {
        service.fetchTrainParts { options in
            DispatchQueue.main.async {
                self.trainOptions = options
                self.fetchAllExercises(options:self.trainOptions)
            }
        }
    }
    
    func fetchAllExercises(options:[String]) {
        service.fetchAllExercises(for: options) { exercises in
            DispatchQueue.main.async {
                self.allExercises = exercises
                self.filterExercises = self.allExercises
            }
        }
    }
    
    func searchExerciseName(for name: String) {
        var filteredExercises: [Exercise] = []
        allExercises.forEach { exercise in
            if exercise.name.contains(name) {
                filteredExercises.append(exercise)
            }
            if name == "" {
                filteredExercises = allExercises
            }
        }
        filterExercises = filteredExercises
    }
    
    func searchExercisePart() {
        var filteredExercises: [Exercise] = []
        if selectedExercisePart == nil {
            filteredExercises = allExercises
        } else {
            allExercises.forEach { exercise in
                if exercise.part.contains(selectedExercisePart!.rawValue) {
                    filteredExercises.append(exercise)
                }
            }
        }
        filterExercises = filteredExercises
    }
    
    func toggleExercisePart(part: ExercisePart) {
        if let index =  selectedExerciseParts.firstIndex(of: part) {
            selectedExerciseParts.remove(at: index)
        } else {
            selectedExerciseParts.append(part)
        }
    }
    
    func onTapExercisePartToggle(part: ExercisePart){
        toggleExercisePart(part: part)
        searchExercisePart()
    }
    
}

