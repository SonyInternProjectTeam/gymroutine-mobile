import SwiftUI

struct SearchUserView: View {
    @StateObject private var viewModel = SearchUserViewModel()
    @FocusState private var isFocused: Bool
    @State private var showCancelButton: Bool = false
    
    private let Usercolumns: [GridItem] = [
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                UserSearchField(text:$viewModel.searchName, onSubmit: {
                    viewModel.fetchUsers()
                })
                .focused($isFocused)
                .onChange(of: viewModel.searchName) {
                    viewModel.fetchUsers()
                }
                .onChange(of: isFocused) {
                    withAnimation{
                        showCancelButton = isFocused
                        viewModel.searchName = ""
                        viewModel.fetchUsers()
                    }
                }
                if showCancelButton {
                    Button("キャンセル") {
                        withAnimation{
                            isFocused = false
                            showCancelButton = false
                            
                        }
                    }
                }
            }
            if (isFocused) {
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
            } else {
                //                RecommendUserView
            }
        }
        .padding([.top, .horizontal], 24)
        .background(.gray.opacity(0.03))
        Spacer()
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
    
    //    private func userProfileView(for user: (name: String, age: String, gender: String, profilePhoto: String)) -> some View {
    //        VStack {
    //            HStack {
    //                if !user.profilePhoto.isEmpty {
    //                    AsyncImage(url: URL(string: user.profilePhoto)) { image in
    //                        image.resizable().scaledToFit()
    //                    } placeholder: {
    //                        ProgressView()
    //                    }
    //                    .frame(width: 56, height: 56)
    //                    .clipShape(Circle())
    //                } else {
    //                    Image(systemName: "person.circle")
    //                        .resizable()
    //                        .frame(width: 56, height: 56)
    //                        .foregroundColor(.gray)
    //                }
    //                VStack{
    //                    Text(String(user.age) + "歳" + " " + String(user.gender))
    //                        .font(.caption)
    //                        .fontWeight(.thin)
    //                    Text(user.name)
    //                        .font(.subheadline)
    //                        .fontWeight(.bold)
    //                }
    //                .frame(width: 74, height: 56)
    //            }
    //
    //
    //            Button(action: {
    //                //                フォロー処理
    //            }) {
    //                Text("フォロー")
    //                    .foregroundStyle(Color.black)
    //                    .font(.caption)
    //                    .fontWeight(.semibold)
    //
    //            }
    //            .buttonStyle(PrimaryButtonStyle())
    //            .frame(width: 140, height: 28)
    //        }
    //        .frame(width: 156, height: 116)
    //        .border(Color.blue, width: 3)
    //    }
    
    
    //    private func userListView(for user: (name: String, age: String, gender: String, profilePhoto: String)) -> some View {
    //>>>>>>> aa8eecb (UI作成)
    //        HStack {
    //            if !user.profilePhoto.isEmpty, let url = URL(string: user.profilePhoto) {
    //                AsyncImage(url: url) { image in
    //                    image.resizable().scaledToFit()
    //                } placeholder: {
    //                    ProgressView()
    //                }
    //                .frame(width: 56, height: 56)
    //                .clipShape(Circle())
    //            } else {
    //                Image(systemName: "person.circle")
    //                    .resizable()
    //                    .frame(width: 56, height: 56)
    //                    .foregroundColor(.gray)
    //            }
    //            VStack {
    //                Text(user.name)
    //                    .font(.subheadline)
    //                    .fontWeight(.bold)
    //                Text(String(user.age) + "歳" + " " + String(user.gender))
    //                    .font(.caption)
    //                    .fontWeight(.thin)
    //            }
    //        }
    //    }
    
    
    struct UserSearchField: View {
        @Binding var text: String
        var onSubmit: () -> Void = { }
        var body: some View {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("ユーザーを検索", text: $text)
                    .onChange(of: text) {
                    }
            }
            .fieldBackground()
        }
    }
}

#Preview {
    SearchUserView()
}

