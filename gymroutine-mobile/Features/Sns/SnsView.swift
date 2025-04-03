//
//  SnsView.swift
//  gymroutine-mobile
//
//  Created by 森祐樹 on 2024/12/30.
//

import SwiftUI



struct SnsView: View {
    @StateObject private var viewModel = SnsViewModel()
    @FocusState private var isFocused: Bool
    @State private var searchMode: Bool = false

    // 테스트용 추천 사용자 데이터
    let testUsers: [User] = [
        User(uid: "5CKiKZmOzlhkEECu4VBDZGltkrn2",
             email: "wkk03240324@gmail.com",
             name: "Kakeru Koizumi",
             profilePhoto: "",
             visibility: 2,
             isActive: false,
             birthday: Date(timeIntervalSince1970: 1017570720),
             gender: "男",
             createdAt: Date(timeIntervalSince1970: 1735656838)
            ),
        User(uid: "7KSQ7Wlqr9OFa9j1CXdtBqbGkLU2",
             email: "kazusukechin@gmail.com",
             name: "Kazu",
             profilePhoto: "",
             visibility: 2,
             isActive: false,
             birthday: Date(timeIntervalSince1970: 1704182340),
             gender: "",
             createdAt: Date(timeIntervalSince1970: 1703839169)
            ),
        User(uid: "AIvdESvweDaVwEednWjk6oekzJQ2",
             email: "test4@test.com",
             name: "Test4",
             profilePhoto: "https://firebasestorage.googleapis.com:443/v0/b/gymroutine-b7b6c.appspot.com/o/profile_photos%2FAIvdESvweDaVwEednWjk6oekzJQ2.jpg?alt=media&token=c750172f-c5a5-4f4f-ba05-f18c04278158",
             visibility: 2,
             isActive: false,
             birthday: Date(timeIntervalSince1970: 1733775060),
             gender: "男性",
             createdAt: Date(timeIntervalSince1970: 1733071896)
            )
    ]

    var body: some View {
        VStack(spacing: 16) {
            searchBarView

            if searchMode {
                searchResultsView
            }
            else {
                recommendedUsersView
            }
        }
        .onChange(of: isFocused) {
            // サーチモードOFFのときにフォーカスON → サーチモードON
            withAnimation {
                if !searchMode && isFocused { searchMode = true }
            }
        }
        .navigationTitle("SNS")
        // Large Title을 쓰지 않고 상단 여백을 줄이려면 Inline Title
        .navigationBarTitleDisplayMode(.inline)
    }

    private var searchBarView: some View {
        HStack(spacing: 8) {
            UserSearchField(text: $viewModel.searchName, onSubmit: {
                viewModel.fetchUsers()
            })
            .focused($isFocused)

            if searchMode {
                Button("キャンセル") {
                    // NavigationStack을 닫음
                    withAnimation {
                        isFocused = false
                        searchMode = false
                        viewModel.searchName = ""
                        viewModel.userDetails = []
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var searchResultsView: some View {
        Group {
            // 검색 결과 / 오류 / 결과 없음 표시
            if let errorMessage = viewModel.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
                    .vAlign(.top)
            } else if viewModel.userDetails.isEmpty {
                Text("No results found")
                    .foregroundColor(.gray)
                    .padding()
                    .vAlign(.top)
            } else {
                List(viewModel.userDetails, id: \.uid) { user in
                    NavigationLink(destination: ProfileView(user: user)) {
                        userProfileView(for: user)
                    }
                }
            }
        }
    }

    private var recommendedUsersView: some View {
        // 추천 사용자 영역
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "person.2")
                Text("おすすめ")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.leading, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(testUsers, id: \.uid) { user in
                        // 실제 프로젝트에서는 UserCell, UserProfileView 등 사용
                        UserCell(user: user)
                    }
                }
                .padding(.leading, 16)
            }

            Spacer()
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
    NavigationStack {
        SnsView()
    }
}
