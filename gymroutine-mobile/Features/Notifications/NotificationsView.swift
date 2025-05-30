import SwiftUI

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Text("通知を読み込み中...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                } else if viewModel.allNotifications.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "bell")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("通知がありません")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("新しい通知があると、ここに表示されます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding()
                } else {
                    List {
                        // 그룹 초대 섹션
                        if !viewModel.groupInvitations.isEmpty {
                            Section("グループ招待") {
                                ForEach(viewModel.groupInvitations) { invitation in
                                    GroupInvitationNotificationRow(
                                        invitation: invitation,
                                        onRespond: { accept in
                                            viewModel.respondToGroupInvitation(invitation: invitation, accept: accept)
                                        }
                                    )
                                }
                            }
                        }
                        
                        // 향후 다른 알림 타입들을 여기에 추가할 수 있습니다
                        // 예: 팔로우 요청, 좋아요, 댓글 등
                        
                        // 일반 알림 섹션 (향후 확장용)
                        if !viewModel.otherNotifications.isEmpty {
                            Section("その他の通知") {
                                ForEach(viewModel.otherNotifications, id: \.id) { notification in
                                    GeneralNotificationRow(
                                        notification: notification,
                                        onTap: {
                                            if !notification.isRead {
                                                viewModel.markNotificationAsRead(notificationId: notification.id)
                                            }
                                        }
                                    )
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        if !notification.isRead {
                                            Button("既読") {
                                                viewModel.markNotificationAsRead(notificationId: notification.id)
                                            }
                                            .tint(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("通知")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // 모든 알림 읽음 처리 버튼
                    if viewModel.unreadNotificationsCount > 0 {
                        Button("すべて既読") {
                            viewModel.markAllAsRead()
                        }
                        .font(.caption)
                        .disabled(viewModel.isLoading)
                    }
                    
                    // 새로고침 버튼
                    Button(action: {
                        viewModel.loadAllNotifications()
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
                Text(viewModel.successMessage)
            }
            .onAppear {
                viewModel.loadAllNotifications()
            }
        }
    }
}

// 그룹 초대 알림 행
struct GroupInvitationNotificationRow: View {
    let invitation: GroupInvitation
    let onRespond: (Bool) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.3.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("グループ招待")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                    
                    Text(invitation.groupName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(invitation.invitedByName)さんからの招待")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(invitation.invitedAt, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack {
                Button("辞退") {
                    onRespond(false)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                
                Spacer()
                
                Button("参加") {
                    onRespond(true)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

// 일반 알림 행 (향후 확장용)
struct GeneralNotificationRow: View {
    let notification: GeneralNotification
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: notification.iconName)
                .font(.title2)
                .foregroundColor(Color(notification.iconColor))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.headline)
                    .fontWeight(notification.isRead ? .medium : .semibold)
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(notification.createdAt, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(notification.isRead ? 0.5 : 1.0))
        .cornerRadius(12)
        .onTapGesture {
            onTap()
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

// 일반 알림 모델 (향후 확장용)
struct GeneralNotification: Identifiable {
    let id: String
    let title: String
    let message: String
    let iconName: String
    let iconColor: String
    let createdAt: Date
    let isRead: Bool
    let type: NotificationType
}

enum NotificationType: String, CaseIterable {
    case groupInvitation = "group_invitation"
    case newFollower = "new_follower"
    case groupGoalCreated = "group_goal_created"
    case followRequest = "follow_request"
    case like = "like"
    case comment = "comment"
    case workout = "workout"
    case achievement = "achievement"
}

#Preview {
    NotificationsView()
} 