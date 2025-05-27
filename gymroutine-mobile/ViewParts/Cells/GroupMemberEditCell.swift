import SwiftUI

struct GroupMemberEditCell: View {
    let member: GroupMember
    let viewModel: GroupEditViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // 프로필 이미지
            Image(systemName: "person.circle.fill")
                .foregroundColor(.gray)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(member.userName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("参加日: \(member.joinedAt, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(member.role.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(member.role == .admin ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
                    .foregroundColor(member.role == .admin ? .orange : .blue)
                    .clipShape(Capsule())
                
                if member.role != .admin {
                    Button(action: {
                        viewModel.removeMember(member)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

#Preview {
    GroupMemberEditCell(
        member: GroupMember(
            id: "1",
            userId: "user1",
            userName: "テストユーザー",
            joinedAt: Date(),
            role: .member
        ),
        viewModel: GroupEditViewModel()
    )
} 