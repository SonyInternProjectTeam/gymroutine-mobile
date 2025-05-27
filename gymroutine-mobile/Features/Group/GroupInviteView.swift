import SwiftUI

struct GroupInviteView: View {
    let groupId: String
    @StateObject private var viewModel = GroupInviteViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // 검색 바
                HStack {
                    TextField("ユーザー名で検索", text: $viewModel.searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            viewModel.searchUsers()
                        }
                    
                    Button("検索") {
                        viewModel.searchUsers()
                    }
                    .disabled(viewModel.searchQuery.isEmpty || viewModel.isLoading)
                }
                .padding(.horizontal)
                
                // 검색 결과
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else if viewModel.searchResults.isEmpty && !viewModel.lastSearchedQuery.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("「\(viewModel.lastSearchedQuery)」に一致するユーザーがいません")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Text("別のキーワードで検索してみてください")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                } else if viewModel.searchResults.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "person.2")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("ユーザーを検索")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("ユーザー名を入力してメンバーを招待しましょう")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding()
                } else {
                    List(viewModel.searchResults, id: \.uid) { user in
                        HStack {
                            // 프로필 이미지
                            AsyncImage(url: URL(string: user.profilePhoto)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading) {
                                Text(user.name)
                                    .font(.headline)
                                
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if viewModel.invitedUsers.contains(user.uid) {
                                Text("招待済み")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.1))
                                    .clipShape(Capsule())
                            } else {
                                Button("招待") {
                                    viewModel.inviteUser(userId: user.uid, groupId: groupId)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("メンバー招待")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.refreshUsers(groupId: groupId)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.headline)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("成功", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") { }
            } message: {
                Text("招待を送信しました！")
            }
            .onAppear {
                // 뷰가 나타날 때 초대 상태 로드
                viewModel.loadInvitationStatuses(groupId: groupId)
            }
        }
    }
}

#Preview {
    GroupInviteView(groupId: "sample-group-id")
} 
