import Foundation

@MainActor
final class SearchUserViewModel: ObservableObject {
    @Published var userDetails: [(name: String, profilePhoto: String)] = []
    @Published var searchName: String = ""
    @Published var errorMessage: String? = nil
    
    private let userService = UserService()
    
    func fetchUsers() {
        Task {
            let result = await userService.searchUsersByName(name: searchName)
            switch result {
            case .success(let users):
                userDetails = users.map { (name: $0.name, profilePhoto: $0.profilePhoto) }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}
