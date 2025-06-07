import SwiftUI

struct GroupDetailView: View {
    let group: GroupModel
    var isNewlyJoined: Bool = false
    @StateObject private var viewModel = GroupDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    private let analyticsService = AnalyticsService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 그룹 헤더
                VStack(spacing: 16) {
                    // 그룹 이미지
                    // ZStack {
                    //     RoundedRectangle(cornerRadius: 16)
                    //         .fill(Color.blue.opacity(0.1))
                    //         .frame(height: 200)
                        
                    //     // imageUrl이 주석처리되어 있으므로 기본 아이콘만 표시
                    //     Image(systemName: "person.3.fill")
                    //         .font(.system(size: 60))
                    //         .foregroundColor(.blue)
                    // }
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text(group.name)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            if group.isPrivate {
                                Label("プライベート", systemImage: "lock.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        if let description = group.description, !description.isEmpty {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        
                        HStack {
                            Label("\(group.memberCount)名", systemImage: "person.2")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("作成日: \(group.createdAt, formatter: dateFormatter)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if !group.tags.isEmpty {
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 80))
                            ], spacing: 8) {
                                ForEach(group.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(.systemBlue).opacity(0.1))
                                        .foregroundColor(.accentColor)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // 탭 섹션
                VStack(spacing: 0) {
                    // 탭 헤더
                    HStack(spacing: 0) {
                        ForEach(GroupDetailTab.allCases, id: \.self) { tab in
                            Button(action: {
                                viewModel.selectedTab = tab
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: tab.iconName)
                                        .font(.title3)
                                    Text(tab.title)
                                        .font(.caption)
                                }
                                .foregroundColor(viewModel.selectedTab == tab ? .accentColor : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                        }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 탭 컨텐츠
                    VStack {
                        switch viewModel.selectedTab {
                        case .members:
                            GroupMembersView(groupId: group.id ?? "", viewModel: viewModel)
                        case .goals:
                            GroupGoalsView(groupId: group.id ?? "", viewModel: viewModel)
                        case .stats:
                            GroupStatsView(groupId: group.id ?? "", viewModel: viewModel)
                        }
                    }
                    .padding(.top)
                }
            }
            .padding()
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isCurrentUserAdmin {
                    NavigationLink(destination: GroupEditView(group: group)) {
                        Image(systemName: "gearshape")
                            .font(.headline)
                    }
                }
            }
        }
        .onAppear {
            print("🔄 [GroupDetailView] onAppear - Loading group data for group: \(group.id ?? "unknown") with isNewlyJoined: \(isNewlyJoined)")
            viewModel.loadGroupData(groupId: group.id ?? "", isNewlyJoined: isNewlyJoined)
            analyticsService.logScreenView(screenName: "GroupDetail")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("GroupDeleted"))) { _ in
            // 그룹이 삭제되었을 때 현재 뷰도 닫기
            dismiss()
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

// New cell for pending members
struct PendingMemberCell: View {
    let pendingMember: PendingMemberDisplay

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: pendingMember.profilePhotoUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(pendingMember.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("招待日: \(pendingMember.invitationDate, formatter: cellDateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("招待中") // "Pending"
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // Renamed to avoid conflict with view's dateFormatter if any, and added timeStyle
    private var cellDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short 
        return formatter
    }
}

struct GroupMembersView: View {
    let groupId: String
    @ObservedObject var viewModel: GroupDetailViewModel
    @State private var showingInviteSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) { // Increased spacing
            // Existing Members Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("グループメンバー (\(viewModel.members.count)名)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if viewModel.isCurrentUserAdmin {
                        Button("招待") {
                            showingInviteSheet = true
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemBlue))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
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
                            GroupMemberCell(member: member)
                        }
                    }
                }
            }
            
            // Pending Invitations Section - 모든 멤버가 볼 수 있도록 변경
            VStack(alignment: .leading, spacing: 12) {
                if !viewModel.pendingMembers.isEmpty || viewModel.isLoadingPendingMembers {
                    Text("招待中のメンバー (\(viewModel.pendingMembers.count)名)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.top) // Add some top padding
                }

                if viewModel.isLoadingPendingMembers {
                    HStack {
                        Spacer()
                        ProgressView()
                        Text("招待中メンバーを読み込み中...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                } else if viewModel.pendingMembers.isEmpty {
                    // 로딩 중이 아니고 pending members가 없을 때만 표시
                    if !viewModel.isLoadingMembers {
                        Text("招待中のメンバーはいません")
                            .foregroundColor(.secondary)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.pendingMembers) { pendingMember in
                            PendingMemberCell(pendingMember: pendingMember)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingInviteSheet) {
            GroupInviteView(groupId: groupId)
        }
    }
}

struct GroupMemberCell: View {
    let member: GroupMember
    
    var body: some View {
        HStack(spacing: 12) {
            // 프로필 이미지 (userProfileImageUrl 필드가 GroupMember에 없으므로 기본 아이콘 사용)
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
            
            Text(member.role.displayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(member.role == .admin ? Color.orange.opacity(0.1) : Color(.systemBlue).opacity(0.1))
                .foregroundColor(member.role == .admin ? .orange : .accentColor)
                .clipShape(Capsule())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

struct GroupGoalsView: View {
    let groupId: String
    @ObservedObject var viewModel: GroupDetailViewModel
    @State private var showingGoalCreate = false
    
    // 활성 목표와 완료된 목표 분리
    private var activeGoals: [GroupGoal] {
        viewModel.goals.filter { $0.status == .active }
    }
    
    private var completedGoals: [GroupGoal] {
        viewModel.goals.filter { $0.status == .completed }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("グループ目標")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                                // 임시 테스트 버튼들 (관리자만)
                // if viewModel.isCurrentUserAdmin {
                //     HStack(spacing: 8) {
                //         Button("🔄 갱신") {
                //             viewModel.manualRenewRepeatingGoals(groupId: groupId)
                //         }
                //         .font(.caption)
                //         .padding(.horizontal, 8)
                //         .padding(.vertical, 4)
                //         .background(Color.orange)
                //         .foregroundColor(.white)
                //         .clipShape(Capsule())
                        
                //         Button("✅ 완료확인") {
                //             viewModel.checkGoalCompletion(groupId: groupId)
                //         }
                //         .font(.caption)
                //         .padding(.horizontal, 8)
                //         .padding(.vertical, 4)
                //         .background(Color.green)
                //         .foregroundColor(.white)
                //         .clipShape(Capsule())
                //     }
                // }
                
                if viewModel.isCurrentUserAdmin {
                    Button("目標追加") {
                        showingGoalCreate = true
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
            }
            
            if viewModel.isLoadingGoals {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            } else if viewModel.goals.isEmpty {
                Text("設定された目標がありません")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                LazyVStack(spacing: 16) {
                    // 활성 목표 섹션
                    if !activeGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("進行中の目標 (\(activeGoals.count))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            
                            LazyVStack(spacing: 12) {
                                ForEach(activeGoals) { goal in
                                    GroupGoalCell(goal: goal, groupId: groupId, viewModel: viewModel)
                                }
                            }
                        }
                    }
                    
                    // 완료된 목표 섹션
                    if !completedGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("完了した目標 (\(completedGoals.count))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            
                            LazyVStack(spacing: 12) {
                                ForEach(completedGoals) { goal in
                                    GroupGoalCell(goal: goal, groupId: groupId, viewModel: viewModel)
                                        .opacity(0.8) // 완료된 목표는 조금 투명하게
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingGoalCreate) {
            GroupGoalCreateView(groupId: groupId)
        }
    }
}

struct GroupGoalCell: View {
    let goal: GroupGoal
    let groupId: String
    @ObservedObject var viewModel: GroupDetailViewModel
    @EnvironmentObject var authService: AuthService
    
    @State private var showingProgressInputAlert = false
    @State private var currentProgressInput: String = ""
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    
    private var currentUserProgress: Double {
        guard let userId = authService.currentUser?.uid else { return 0 }
        return goal.currentProgress[userId] ?? 0
    }
    
    private var isGoalAchievedByCurrentUser: Bool {
        currentUserProgress >= goal.targetValue
    }
    
    // 현재 사용자가 목표 생성자인지 확인
    private var isGoalCreator: Bool {
        guard let userId = authService.currentUser?.uid else { return false }
        return goal.createdBy == userId
    }
    
    // Check if the current user is a member of the group
    private var isCurrentUserMember: Bool {
        guard let currentUserId = authService.currentUser?.uid else { return false }
        return viewModel.members.contains { $0.userId == currentUserId }
    }
    
    // 반복 정보 텍스트 생성
    private var repeatInfoText: String? {
        guard let repeatType = goal.repeatType, repeatType != "none",
              let repeatCount = goal.repeatCount else { return nil }
        
        let cycleInfo = goal.currentRepeatCycle != nil ? " (\(goal.currentRepeatCycle!)/\(repeatCount))" : ""
        
        switch repeatType {
        case "weekly":
            return "週次反復 \(repeatCount)回\(cycleInfo)"
        case "monthly":
            return "月次反復 \(repeatCount)回\(cycleInfo)"
        default:
            return nil
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack(spacing: 8) {
                    // 목표 상태 표시
                    Text(goal.actualStatus.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(goal.actualStatus.displayColor).opacity(0.1))
                        .foregroundColor(Color(goal.actualStatus.displayColor))
                        .clipShape(Capsule())
                    
                    Text(goal.goalType.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .clipShape(Capsule())
                    
                    // 목표 관리 메뉴 (생성자만 볼 수 있음)
                    if isGoalCreator {
                        Menu {
                            Button {
                                showingEditSheet = true
                            } label: {
                                Label("編集", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                showingDeleteAlert = true
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .frame(width: 24, height: 24)
                        }
                    }
                }
            }
            
            if let description = goal.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("目標: \(Int(goal.targetValue)) \(goal.unit)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(goal.startDate, formatter: dateFormatter) - \(goal.endDate, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 반복 정보 표시
                if let repeatInfo = repeatInfoText {
                    HStack {
                        Image(systemName: "repeat")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        
                        Text(repeatInfo)
                            .font(.caption)
                            .foregroundColor(.accentColor)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                }
            }
            
            // User's progress section
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("あなたの進捗: \(Int(currentUserProgress)) / \(Int(goal.targetValue)) \(goal.unit)")
                        .font(.caption)
                        .foregroundColor(goal.status == .completed ? .green : (isGoalAchievedByCurrentUser ? .green : .orange))
                    Spacer()
                    
                    if goal.status == .completed {
                        Text("目標完了！🎉")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    } else if !isGoalAchievedByCurrentUser && isCurrentUserMember {
                        Button("進捗更新") {
                            // Reset input field before showing alert
                            currentProgressInput = "\(Int(currentUserProgress))"
                            showingProgressInputAlert = true
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemBlue).opacity(0.8))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    } else {
                        Text("達成済み！🎉")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                
                // 사용자 진행률 ProgressView - 값을 안전한 범위로 클램프
                let safeUserProgress = max(0, min(currentUserProgress, goal.targetValue))
                let safeTargetValue = max(0.1, goal.targetValue) // 0으로 나누기 방지
                ProgressView(value: safeUserProgress, total: safeTargetValue)
                    .progressViewStyle(LinearProgressViewStyle(tint: isGoalAchievedByCurrentUser ? .green : .orange))
            }
            .padding(.top, 5)
            
            // Overall group progress bar - 달성한 멤버 수 기준으로 계산
            let totalMembers = viewModel.members.count
            let achievedMembers = goal.currentProgress.values.filter { $0 >= goal.targetValue }.count
            let groupProgressPercentage = totalMembers > 0 ? Double(achievedMembers) / Double(totalMembers) : 0.0
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("グループ全体の進捗")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    // 달성한 멤버 수 표시
                    Text("達成: \(achievedMembers)/\(totalMembers)名")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(achievedMembers == totalMembers ? .green : .primary)
                }
                
                // 그룹 진행률 ProgressView - 달성한 멤버 비율로 표시
                ProgressView(value: groupProgressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: achievedMembers == totalMembers ? .green : .accentColor))
            }
            .padding(.top, 5)
            
            // 멤버별 진행률 섹션
            if !goal.currentProgress.isEmpty || !viewModel.members.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("メンバー別進捗")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(goal.currentProgress.count)名が参加中")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // 멤버별 진행률 리스트 (진행률 높은 순으로 정렬, 최대 5명)
                    let sortedMemberProgress = createSortedMemberProgressList()
                    
                    LazyVStack(spacing: 4) {
                        ForEach(sortedMemberProgress.prefix(5), id: \.userId) { memberProgress in
                            MemberProgressRow(
                                memberProgress: memberProgress,
                                goalTargetValue: goal.targetValue,
                                goalUnit: goal.unit
                            )
                        }
                        
                        // 더 많은 멤버가 있는 경우 표시
                        if sortedMemberProgress.count > 5 {
                            HStack {
                                Spacer()
                                Text("他 \(sortedMemberProgress.count - 5)名...")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.top, 2)
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(.systemGray5).opacity(0.5))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .alert("進捗を更新", isPresented: $showingProgressInputAlert) {
            TextField("新しい進捗 (\(goal.unit))", text: $currentProgressInput)
                .keyboardType(.numberPad)
            Button("更新") {
                if let newProgress = Double(currentProgressInput), let goalId = goal.id {
                    // Ensure progress doesn't exceed target, or handle as needed
                    let progressToUpdate = min(newProgress, goal.targetValue)
                    Task {
                        await viewModel.updateUserGoalProgress(goalId: goalId, newProgress: progressToUpdate, groupId: groupId)
                    }
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("現在の目標「\(goal.title)」の進捗を入力してください。最大値: \(Int(goal.targetValue)) \(goal.unit)")
        }
        .alert("目標を削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                if let goalId = goal.id {
                    Task {
                        await viewModel.deleteGoal(goalId: goalId, groupId: groupId)
                    }
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("目標「\(goal.title)」を削除しますか？この操作は元に戻すことができません。")
        }
        .sheet(isPresented: $showingEditSheet) {
            GroupGoalEditView(goal: goal, groupId: groupId)
        }
    }
    
    // 멤버별 진행률 리스트 생성 (진행률 높은 순으로 정렬)
    private func createSortedMemberProgressList() -> [MemberProgressData] {
        var memberProgressList: [MemberProgressData] = []
        
        // 현재 진행률이 있는 멤버들
        for (userId, progress) in goal.currentProgress {
            let memberName = viewModel.members.first { $0.userId == userId }?.userName ?? "Unknown User"
            memberProgressList.append(MemberProgressData(
                userId: userId,
                userName: memberName,
                progress: progress,
                isAchieved: progress >= goal.targetValue
            ))
        }
        
        // 진행률이 없는 멤버들도 추가 (진행률 0으로)
        for member in viewModel.members {
            if goal.currentProgress[member.userId] == nil {
                memberProgressList.append(MemberProgressData(
                    userId: member.userId,
                    userName: member.userName,
                    progress: 0,
                    isAchieved: false
                ))
            }
        }
        
        // 진행률 높은 순, 같으면 이름 순으로 정렬
        return memberProgressList.sorted { first, second in
            if first.progress != second.progress {
                return first.progress > second.progress
            }
            return first.userName < second.userName
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

// 멤버 진행률 데이터 구조
struct MemberProgressData {
    let userId: String
    let userName: String
    let progress: Double
    let isAchieved: Bool
}

// 멤버별 진행률 행 컴포넌트
struct MemberProgressRow: View {
    let memberProgress: MemberProgressData
    let goalTargetValue: Double
    let goalUnit: String
    
    var body: some View {
        HStack(spacing: 8) {
            // 멤버 이름
            Text(memberProgress.userName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(maxWidth: 80, alignment: .leading)
            
            // 진행률 바
            let safeProgress = max(0, min(memberProgress.progress, goalTargetValue))
            let safeTarget = max(0.1, goalTargetValue)
            
            ProgressView(value: safeProgress, total: safeTarget)
                .progressViewStyle(LinearProgressViewStyle(tint: memberProgress.isAchieved ? .green : .orange))
                .frame(height: 4)
            
            // 진행률 수치와 달성 상태
            HStack(spacing: 4) {
                Text("\(Int(memberProgress.progress))/\(Int(goalTargetValue))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(minWidth: 40, alignment: .trailing)
                
                if memberProgress.isAchieved {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "circle")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
}

struct GroupStatsView: View {
    let groupId: String
    @ObservedObject var viewModel: GroupDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("グループ統計")
                .font(.headline)
                .fontWeight(.semibold)
            
            // 개발중 메시지 표시
            VStack(spacing: 16) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                
                Text("開発中です")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("グループ統計機能は現在開発中です。\n近日中にリリース予定です。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .padding(.horizontal, 20)
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
                    VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        GroupDetailView(group: GroupModel(
            id: "1",
            name: "헬스 친구들",
            description: "함께 운동하는 친구들의 모임입니다. 서로 격려하며 건강한 라이프스타일을 만들어가요!",
            createdBy: "user1",
            createdAt: Date(),
            updatedAt: Date(),
            memberCount: 12,
            isPrivate: false,
            tags: ["헬스", "근력운동", "다이어트"]
        ))
    }
} 