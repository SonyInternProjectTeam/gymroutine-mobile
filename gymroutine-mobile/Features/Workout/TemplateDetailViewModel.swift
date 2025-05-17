//
//  TemplateDetailViewModel.swift
//  gymroutine-mobile
//
//  Created by AIDE on 2025/05/17.
//

import SwiftUI
import FirebaseFirestore

class TemplateDetailViewModel: ObservableObject {
    private let workoutService = WorkoutService()
    private let authService = AuthService()
    
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    private let template: WorkoutTemplate
    
    init(template: WorkoutTemplate) {
        self.template = template
    }
    
    func addTemplateToUserWorkouts(completion: @escaping (Bool) -> Void) {
        guard let currentUser = authService.getCurrentUser() else {
            showAlert(title: "エラー", message: "ログインしてください")
            return
        }
        
        isLoading = true
        
        // 템플릿에서 워크아웃 생성
        let workout = Workout(
            id: UUID().uuidString,
            userId: currentUser.uid,
            name: template.name,
            createdAt: Timestamp(date: Date()).dateValue(),
            notes: template.notes,
            isRoutine: true,  // 템플릿은 항상 루틴으로 설정
            scheduledDays: template.scheduledDays,
            exercises: template.exercises
        )
        
        // 워크아웃 저장
        Task {
            let result = await workoutService.createWorkout(workout: workout)
            
            await MainActor.run {
                isLoading = false
                
                switch result {
                case .success:
                    showAlert(title: "追加完了", message: "テンプレートがあなたのワークアウトとして追加されました")
                    completion(true)
                case .failure(let error):
                    showAlert(title: "エラー", message: "テンプレートの追加に失敗しました: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }
    
    func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
} 