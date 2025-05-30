import SwiftUI

/// 그룹 생성 및 관리를 위한 뷰
/// 이동 경로: SnsView → GroupManagementView (그룹 섹션의 "+" 버튼 클릭)
struct GroupManagementView: View {
    @StateObject private var viewModel = GroupManagementViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 그룹 생성 폼
                VStack(alignment: .leading, spacing: 16) {
                    Text("新しいグループを作成")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("グループ名")
                            .font(.headline)
                        
                        TextField("グループ名を入力してください", text: $viewModel.groupName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("説明 (任意)")
                            .font(.headline)
                        
                        TextField("グループの説明を入力してください", text: $viewModel.groupDescription, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("プライバシー設定")
                            .font(.headline)
                        
                        Toggle("プライベートグループ", isOn: $viewModel.isPrivate)
                            .toggleStyle(SwitchToggleStyle())
                        
                        Text(viewModel.isPrivate ? "招待されたメンバーのみが参加できます" : "誰でも検索して参加できます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("タグ")
                            .font(.headline)
                        
                        HStack {
                            TextField("タグを追加", text: $viewModel.newTag)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onSubmit {
                                    viewModel.addTag()
                                }
                            
                            Button("追加") {
                                viewModel.addTag()
                            }
                            .disabled(viewModel.newTag.isEmpty)
                        }
                        
                        if !viewModel.tags.isEmpty {
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 80))
                            ], spacing: 8) {
                                ForEach(viewModel.tags, id: \.self) { tag in
                                    HStack {
                                        Text("#\(tag)")
                                            .font(.caption)
                                        
                                        Button(action: {
                                            viewModel.removeTag(tag)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                // 생성 버튼
                Button(action: {
                    viewModel.createGroup()
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        
                        Text("グループを作成")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canCreateGroup ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!viewModel.canCreateGroup || viewModel.isLoading)
            }
            .padding()
            .navigationTitle("グループ作成")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("成功", isPresented: .constant(viewModel.showSuccessAlert)) {
                Button("OK") {
                    viewModel.showSuccessAlert = false
                    dismiss()
                }
            } message: {
                Text("グループが正常に作成されました！")
            }
        }
    }
}



#Preview {
    GroupManagementView()
} 