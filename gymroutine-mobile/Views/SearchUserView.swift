import SwiftUI

struct SearchUserView: View {

    @StateObject private var viewModel = SearchUserViewModel()

    var body: some View {
        NavigationView {
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
                    List(viewModel.userDetails, id: \.name) { user in
                        HStack {
                            if !user.profilePhoto.isEmpty {
                                AsyncImage(url: URL(string: user.profilePhoto)) { image in
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
            }
            .navigationTitle("Search Users")
        }
    }
}
