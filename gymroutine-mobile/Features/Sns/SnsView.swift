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
        .onAppear {
            // 画面表示時におすすめユーザーを生成して取得
            viewModel.initializeRecommendations()
        }
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
                    NavigationLink {
                        ProfileView(viewModel: ProfileViewModel(user: user), router: nil)
                    } label: {
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
                Text("おすすめユーザー")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    // おすすめリストを更新
                    viewModel.refreshRecommendations()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.headline)
                }
                .disabled(viewModel.isLoadingRecommendations)
            }
            .padding(.horizontal, 16)
            
            if viewModel.isLoadingRecommendations {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if let error = viewModel.recommendationsError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .padding(.horizontal, 16)
            } else if viewModel.recommendedUsers.isEmpty {
                VStack(alignment: .center) {
                    Text("おすすめユーザーが見つかりませんでした")
                        .foregroundColor(.gray)
                        .padding()
                    
                    Button("再取得") {
                        viewModel.refreshRecommendations()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 30)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.recommendedUsers) { recommendedUser in
                            recommendedUserCell(for: recommendedUser)
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 8)
                }
            }

            Spacer()
        }
    }

    /// 추천 사용자 셀 뷰
    private func recommendedUserCell(for recommendedUser: RecommendedUser) -> some View {
        let user = recommendedUser.user
        
        return NavigationLink {
            ProfileView(viewModel: ProfileViewModel(user: user), router: nil)
        } label: {
            VStack(alignment: .center, spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    // 프로필 이미지
                    profileImageView(for: user)
                        .frame(width: 100, height: 100)
                        .shadow(radius: 3)
                    
                    // 매칭 퍼센트 뱃지
                    Text("\(recommendedUser.matchPercentage)%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.blue)
                        .clipShape(Capsule())
                        .offset(x: 0, y: 3)
                }
                
                // 사용자 이름
                Text(user.name)
                    .font(.headline)
                    .lineLimit(1)
                
                // 추천 이유
                Text(recommendedUser.recommendationReason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 120)
            }
            .frame(width: 130)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    /// 사용자의 프로필 정보를 표시하는 뷰 (필요에 따라 리팩토링)
    private func userProfileView(for user: User) -> some View {
        HStack {
            profileImageView(for: user)
                .frame(width: 50, height: 50)
            
            Text(user.name)
                .font(.headline)
        }
    }
    
    /// 프로필 이미지 뷰
    private func profileImageView(for user: User) -> some View {
        Group {
            if !user.profilePhoto.isEmpty, let url = URL(string: user.profilePhoto) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
                    .clipShape(Circle())
            }
        }
    }
}

#Preview {
    NavigationStack {
        SnsView()
    }
}
