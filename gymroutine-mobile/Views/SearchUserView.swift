import SwiftUI

struct SearchUserView: View {
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
