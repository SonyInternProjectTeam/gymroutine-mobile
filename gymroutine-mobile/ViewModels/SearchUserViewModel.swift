import Foundation

class SearchUserViewModel: ObservableObject {
    @Published var userDetails: [(name: String, profilePhoto: String)] = []
    @Published var errorMessage: String? = nil
    
    private let userService = UserService()
    
    func fetchUsers(byName name: String) async {
        let result = await userService.searchUsersByName(name: name)
        switch result {
        case .success(let users):
            userDetails = users.map { (name: $0.name, profilePhoto: $0.profilePhoto) }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}
