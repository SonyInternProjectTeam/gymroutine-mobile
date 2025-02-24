import Foundation

@MainActor
final class SearchUserViewModel: ObservableObject {
    @Published var userDetails: [User] = []       // User 型の配列に変更
//    @Published var userDetails: [(name: String, age: String, gender: String, profilePhoto: String)] = []
//    @Published var Test: [(name: String, age: String, gender: String, profilePhoto: String)] = []

    @Published var searchName: String = ""
    @Published var errorMessage: String? = nil
    
    private let userService = UserService()
    
    /// ユーザー名でユーザー検索を行い、結果を userDetails に設定する
    func fetchUsers() {
        Task {
            let result = await userService.searchUsersByName(name: searchName)
            switch result {
            case .success(let users):
                // 直接 User 型の配列を設定
                userDetails = users
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}
    
//    func fetchTest() {
//        Task {
//            let result = await userService.getAllUsers()
//            switch result {
//            case .success(let users):
//                Test = users.map { (name: $0.name, age: returnage(birthday: $0.birthday), gender: $0.gender, profilePhoto: $0.profilePhoto) }
//            case .failure(let error):
//                errorMessage = error.localizedDescription
//            }
//        }
//    }
//    
//    func fetchRecommendUser() {
//        Task {
//            let result = await userService.getAllUsers()
//            switch result {
//            case .success(let users):
//                Test = users.map { (name: $0.name, age: returnage(birthday: $0.birthday), gender: $0.gender, profilePhoto: $0.profilePhoto) }
//            case .failure(let error):
//                errorMessage = error.localizedDescription
//            }
//        }
//    }
//    
//    func returnage(birthday: Date?) -> String {
//        let calendar = Calendar.current
//        let now = Date()
//        // 年齢を計算
//        let ageComponents = calendar.dateComponents([.year], from: birthday!, to: now)
//        return String(ageComponents.year!)
//    }
//}
