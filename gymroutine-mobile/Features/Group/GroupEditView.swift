import SwiftUI

struct GroupEditView: View {
    let group: GroupModel
    @StateObject private var viewModel = GroupEditViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    private let analyticsService = AnalyticsService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 그룹 정보 편집 섹션
                VStack(alignment: .leading, spacing: 16) {
                    Text("グループ情報")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("グループ名")
                            .font(.headline)
                        
                        TextField("グループ名", text: $viewModel.groupName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("説明")
                            .font(.headline)
                        
                        TextField("グループの説明", text: $viewModel.groupDescription, axis: .vertical)
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
                
                // 멤버 관리 섹션
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("メンバー管理")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button("招待") {
                            viewModel.showInviteSheet = true
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
                    
                    if viewModel.isLoadingMembers {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding()
                    } else if viewModel.members.isEmpty {
                        Text("メンバーがいません")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.members) { member in
                                GroupMemberEditCell(member: member, viewModel: viewModel)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 목표 관리 섹션
                VStack(alignment: .leading, spacing: 16) {
                    Text("目標管理")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    NavigationLink(destination: GroupGoalCreateView(groupId: group.id ?? "")) {
                        HStack {
                            Image(systemName: "target")
                            Text("新しい目標を作成")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 위험한 작업 섹션
                VStack(alignment: .leading, spacing: 16) {
                    Text("危険な操作")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Button(action: {
                        viewModel.showDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("グループを削除")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("グループ設定")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    viewModel.updateGroup()
                }
                .disabled(!viewModel.hasChanges || viewModel.isLoading)
            }
        }
        .onAppear {
            viewModel.initialize(with: group)
            analyticsService.logScreenView(screenName: "GroupEdit")
        }
        .alert("グループを削除しますか？", isPresented: $viewModel.showDeleteAlert) {
            Button("削除", role: .destructive) {
                viewModel.deleteGroup()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("この操作は取り消せません。")
        }
        .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("成功", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") {
                if viewModel.isGroupDeleted {
                    // 그룹이 삭제된 경우 네비게이션 스택을 루트까지 되돌림
                    presentationMode.wrappedValue.dismiss()
                    // 추가적으로 부모 뷰들도 닫음
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        NotificationCenter.default.post(name: NSNotification.Name("GroupDeleted"), object: nil)
                    }
                } else {
                    // 그룹이 업데이트된 경우
                    dismiss()
                }
            }
        } message: {
            Text(viewModel.isGroupDeleted ? "グループが正常に削除されました！" : "グループが正常に更新されました！")
        }
        .sheet(isPresented: $viewModel.showInviteSheet) {
            GroupInviteView(groupId: group.id ?? "")
        }
        .alert("メンバーを削除しますか？", isPresented: $viewModel.showRemoveMemberAlert, presenting: viewModel.memberToRemove) { member in
            Button("削除", role: .destructive) {
                viewModel.confirmRemoveMember()
            }
            Button("キャンセル", role: .cancel) { }
        } message: { member in
            Text("「\(member.userName)」さんをグループから削除します。この操作は取り消せません。")
        }
    }
}

#Preview {
    NavigationView {
        GroupEditView(group: GroupModel(
            id: "1",
            name: "헬스 친구들",
            description: "함께 운동하는 친구들의 모임입니다.",
            createdBy: "user1",
            createdAt: Date(),
            updatedAt: Date(),
            memberCount: 12,
            isPrivate: false,
            tags: ["헬스", "근력운동", "다이어트"]
        ))
    }
} 
