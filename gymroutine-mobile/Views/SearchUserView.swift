import SwiftUI

struct SearchUserView: View {
    
    @StateObject private var viewModel = SearchUserViewModel()
    @FocusState private var isFocused: Bool
    @State private var showCancelButton: Bool = false
    
    private let Usercolumns: [GridItem] = [
        GridItem(.flexible())
    ]
    
    let testUsers: [User] = [
        User(uid: "5CKiKZmOzlhkEECu4VBDZGltkrn2",
             email: "wkk03240324@gmail.com",
             name: "Kakeru Koizumi",
             profilePhoto: "",
             visibility: 2,
             isActive: false,
             birthday: Date(timeIntervalSince1970: 1017570720), // 2002-03-31 14:32:00 +0000
             gender: "男",
             createdAt: Date(timeIntervalSince1970: 1735656838) // 2024-12-31 14:33:58 +0000
        ),
        User(uid: "7KSQ7Wlqr9OFa9j1CXdtBqbGkLU2",
             email: "kazusukechin@gmail.com",
             name: "Kazu",
             profilePhoto: "",
             visibility: 2,
             isActive: false,
             birthday: Date(timeIntervalSince1970: 1704182340), // 2024-01-02 05:59:00 +0000
             gender: "",
             createdAt: Date(timeIntervalSince1970: 1703839169) // 2024-12-29 05:59:29 +0000
        ),
        User(uid: "AIvdESvweDaVwEednWjk6oekzJQ2",
             email: "test4@test.com",
             name: "Test4",
             profilePhoto: "https://firebasestorage.googleapis.com:443/v0/b/gymroutine-b7b6c.appspot.com/o/profile_photos%2FAIvdESvweDaVwEednWjk6oekzJQ2.jpg?alt=media&token=c750172f-c5a5-4f4f-ba05-f18c04278158",
             visibility: 2,
             isActive: false,
             birthday: Date(timeIntervalSince1970: 1733775060), // 2024-12-06 06:51:00 +0000
             gender: "男性",
             createdAt: Date(timeIntervalSince1970: 1733071896) // 2024-12-27 06:51:36 +0000
        ),
        User(uid: "AhGAfsGPU8cwvsONT2duSFcQGdJ2",
             email: "yukiyuki1918@icloud.com",
             name: "ああ",
             profilePhoto: "https://firebasestorage.googleapis.com:443/v0/b/gymroutine-b7b6c.appspot.com/o/profile_photos%2FAhGAfsGPU8cwvsONT2duSFcQGdJ2.jpg?alt=media&token=866beab3-b914-4a0c-9128-1fa1cf8c0bc8",
             visibility: 2,
             isActive: false,
             birthday: Date(timeIntervalSince1970: 1736512800), // 2025-01-10 12:40:00 +0000
             gender: "男",
             createdAt: Date(timeIntervalSince1970: 1737999671) // 2025-01-27 12:41:11 +0000
        ),
        User(uid: "FR1jA9UUqKdvV7SUQTZSH0c9Z9G2",
             email: "test001@gmail.com",
             name: "テスト1まさと",
             profilePhoto: "",
             visibility: 2,
             isActive: false,
             birthday: Date(timeIntervalSince1970: 1069868400), // 2003-11-26 15:00:00 +0000
             gender: "男性",
             createdAt: Date(timeIntervalSince1970: 1738125403) // 2025-01-29 03:36:43 +0000
        ),
        User(uid: "zLU7yST5FMatk7uI3zdDD0Ik1qk1",
             email: "sattsat763@icloud.com",
             name: "テストまさと",
             profilePhoto: "",
             visibility: 2,
             isActive: false,
             birthday: Date(timeIntervalSince1970: 1069949580), // 2003-11-27 09:53:00 +0000
             gender: "男性",
             createdAt: Date(timeIntervalSince1970: 1736390040) // 2025-01-08 09:54:00 +0000
        )
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
                    }
                    viewModel.searchName = ""
                    viewModel.userDetails = []
                }
                if showCancelButton {
                    Button("キャンセル") {
                        withAnimation {
                            isFocused = false
                            showCancelButton = false
                        }
                    }
                }
            }
            .padding(.horizontal,16)
            
            if (isFocused) {
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
                            UserListView(user:user)
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                RecommendUserView
            }
        }
        .padding([.top], 24)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(.primary.opacity(0.1))
    }
    
    private var RecommendUserView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack{
                Image(systemName: "person.2")
                Text("おすすめ")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.leading,16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(testUsers, id: \.name) { user in
                        UserProfileView(user: user)
                    }
                }
            }
            .contentMargins(.leading,16)
        }
    }
}

#Preview {
    SearchUserView()
}

