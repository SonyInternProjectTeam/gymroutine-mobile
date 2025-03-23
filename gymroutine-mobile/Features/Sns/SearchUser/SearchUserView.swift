import SwiftUI

struct SearchUserView: View {
    @StateObject private var viewModel = SearchUserViewModel()
    @FocusState private var isFocused: Bool
    @State private var showCancelButton: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                // 검색 입력란 + 취소 버튼
                HStack {
                    UserSearchField(text: $viewModel.searchName, onSubmit: {
                        viewModel.fetchUsers()
                    })
                    .focused($isFocused)
                    .onChange(of: viewModel.searchName) { _ in
                        viewModel.fetchUsers()
                    }
                    
                    if showCancelButton {
                        Button("キャンセル") {
                            // NavigationStack을 닫음
                            dismiss()
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
                
                // 검색 결과 / 오류 / 결과 없음 표시
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
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    /// 사용자의 프로필 정보를 표시하는 뷰 (필요에 따라 리팩토링)
    private func userProfileView(for user: User) -> some View {
        HStack {
            if !user.profilePhoto.isEmpty, let url = URL(string: user.profilePhoto) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFill()
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

#Preview {
    SearchUserView()
}
