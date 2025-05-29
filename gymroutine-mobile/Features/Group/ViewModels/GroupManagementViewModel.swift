import Foundation
import SwiftUI

@MainActor
class GroupManagementViewModel: ObservableObject {
    @Published var groupName: String = ""
    @Published var groupDescription: String = ""
    @Published var isPrivate: Bool = false
    @Published var tags: [String] = []
    @Published var newTag: String = ""
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showSuccessAlert: Bool = false
    
    private let groupService = GroupService()
    
    var canCreateGroup: Bool {
        !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
    
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    func createGroup() {
        Task {
            isLoading = true
            errorMessage = nil
            
            let result = await groupService.createGroup(
                name: groupName.trimmingCharacters(in: .whitespacesAndNewlines),
                description: groupDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : groupDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                isPrivate: isPrivate,
                tags: tags
            )
            
            isLoading = false
            
            switch result {
            case .success(_):
                showSuccessAlert = true
                
                // Send notification that a group was created
                NotificationCenter.default.post(name: AppConstants.NotificationNames.didJoinGroup, object: nil)
                
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
} 