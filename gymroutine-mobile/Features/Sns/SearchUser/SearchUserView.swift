import SwiftUI

struct SearchUserView: View {
    @StateObject private var viewModel = SearchUserViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                // 検索欄
                TextField("Search by name", text: $viewModel.searchName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    viewModel.fetchUsers()
                }) {
                    Text("Search")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)

                // 結果表示
                if let errorMessage = viewModel.errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                } else if viewModel.userDetails.isEmpty {
                    Text("No results found")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(viewModel.userDetails, id: \.uid) { user in
                        NavigationLink(destination: ProfileView(viewModel: ProfileViewModel(user: user), router: nil)) {
                            userProfileView(for: user)
                        }
                    }
                }
            }
            .navigationTitle("Search Users")
        }
    }

    /// ユーザーのプロフィール情報を表示するビュー
    ///  Refactorしないと
    /// - Parameter user: 表示対象の User オブジェクト
    /// - Returns: ユーザー情報を表示する View
    private func userProfileView(for user: User) -> some View {
        HStack {
            if !user.profilePhoto.isEmpty, let url = URL(string: user.profilePhoto) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }
            Text(user.name)
                .font(.headline)
        }
    }
}
