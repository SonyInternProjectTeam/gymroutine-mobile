import SwiftUI

struct SearchUserView: View {
<<<<<<< HEAD
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
                        NavigationLink(destination: ProfileView(viewModel: ProfileViewModel(user: user))) {
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
=======
    @Binding var showOverlay: Bool
    @StateObject private var viewModel = SearchUserViewModel()
    @FocusState private var isFocused: Bool
    @State private var showCancelButton: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                UserSearchField(text: $viewModel.searchName, onSubmit: {
                    viewModel.fetchUsers()
                })
                .focused($isFocused)
                .onChange(of: viewModel.searchName) { _ in
                    viewModel.fetchUsers()
                }
                .onAppear {
                    // 뷰가 나타나면 자동 포커스
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isFocused = true
                    }
                }
                
                if showCancelButton {
                    Button("キャンセル") {
                        // 오버레이를 종료
                        showOverlay = false
                    }
                }
            }
            .padding(.horizontal, 16)
            .onChange(of: isFocused) { newValue in
                withAnimation {
                    showCancelButton = newValue
                }
                if !newValue {
                    viewModel.searchName = ""
                    viewModel.userDetails = []
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            } else if viewModel.userDetails.isEmpty {
                Text("No results found")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView(.vertical) {
                    ForEach(viewModel.userDetails, id: \.name) { user in
                        UserListView(user: user)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.top, 90)
        .background(Color(.systemBackground)) // 확실한 불투명 배경
    }
}

#Preview {
    SearchUserView(showOverlay: .constant(true))
}
>>>>>>> dev
