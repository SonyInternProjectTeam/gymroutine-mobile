import SwiftUI

struct GroupCell: View {
    let groupCell: GroupModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 그룹 이미지 또는 기본 아이콘
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 80)
                
                // imageUrl이 주석처리되어 있으므로 기본 아이콘만 표시
                Image(systemName: "person.3.fill")
                    .font(.title)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(groupCell.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(groupCell.memberCount)名")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if groupCell.isPrivate {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                // 태그 영역 - 태그가 없어도 동일한 높이를 유지하기 위해 항상 표시
                HStack {
                    if !groupCell.tags.isEmpty {
                        ForEach(groupCell.tags.prefix(2), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                        
                        if groupCell.tags.count > 2 {
                            Text("+\(groupCell.tags.count - 2)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        // 태그가 없을 때 빈 공간을 유지하여 일관된 높이 보장
                        Text("")
                            .font(.caption2)
                            .frame(height: 16) // 태그와 동일한 높이
                    }
                    Spacer()
                }
                .frame(height: 20) // 태그 영역의 고정 높이
            }
        }
        .frame(width: 120)
        .padding(.vertical, 8)
    }
}

#Preview {
    GroupCell(groupCell: GroupModel(
        id: "1",
        name: "헬스 친구들",
        description: "함께 운동하는 친구들",
        createdBy: "user1",
        createdAt: Date(),
        updatedAt: Date(),
        memberCount: 5,
        isPrivate: false,
        tags: ["헬스", "근력운동"]
    ))
} 