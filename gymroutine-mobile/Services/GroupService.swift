import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions

class GroupService {
    private let db = Firestore.firestore()
    private let authService = AuthService()
    private let functions = Functions.functions(region: "asia-northeast1")
    
    // MARK: - Group Management
    
    /// 새로운 그룹 생성 (클라이언트에서 직접 처리)
    /// - Parameters:
    ///   - name: 그룹 이름
    ///   - description: 그룹 설명 (선택사항)
    ///   - isPrivate: 비공개 그룹 여부
    ///   - tags: 그룹 태그 배열
    /// - Returns: 생성된 그룹 정보 또는 에러
    func createGroup(name: String, description: String?, isPrivate: Bool, tags: [String]) async -> Result<GroupModel, Error> {
        guard let currentUser = authService.getCurrentUser() else {
            return .failure(NSError(domain: "GroupService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자가 로그인되어 있지 않습니다."]))
        }
        
        do {
            let groupData: [String: Any] = [
                "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
                "description": description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                "createdBy": currentUser.uid,
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date()),
                "memberCount": 1,
                "isPrivate": isPrivate,
                "tags": tags
            ]
            
            let groupRef = try await db.collection("Groups").addDocument(data: groupData)
            
            // 그룹 생성자를 관리자로 추가
            let userName = await authService.getCurrentUserName()
            let memberData: [String: Any] = [
                "userId": currentUser.uid,
                "userName": userName,
                "joinedAt": Timestamp(date: Date()),
                "role": GroupMemberRole.admin.rawValue
            ]
            
            try await db.collection("Groups").document(groupRef.documentID).collection("members").addDocument(data: memberData)
            
            // 생성된 그룹 정보 조회
            let snapshot = try await groupRef.getDocument()
            let group = try snapshot.data(as: GroupModel.self)
            return .success(group)
            
        } catch {
            return .failure(error)
        }
    }
    
    /// 사용자가 속한 그룹 목록 조회 (클라이언트에서 직접 처리)
    /// - Parameters:
    ///   - userId: 조회할 사용자 ID
    /// - Returns: 사용자가 속한 그룹 목록 또는 에러
    func getUserGroups(userId: String) async -> Result<[GroupModel], Error> {
        do {
            // 사용자가 멤버인 그룹 ID들 조회 (컬렉션 그룹 쿼리 사용)
            let memberSnapshot = try await db.collectionGroup("members")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            let groupIds = memberSnapshot.documents.compactMap { document -> String? in
                // 서브컬렉션에서 부모 그룹 ID 추출
                let pathComponents = document.reference.path.components(separatedBy: "/")
                if pathComponents.count >= 3 {
                    return pathComponents[pathComponents.count - 3] // Groups/{groupId}/members/{memberId}
                }
                return nil
            }
            
            if groupIds.isEmpty {
                return .success([])
            }
            
            // Firestore IN 쿼리 제한으로 인해 배치로 처리
            let batchSize = 10
            var groups: [GroupModel] = []
            
            for i in stride(from: 0, to: groupIds.count, by: batchSize) {
                let batch = Array(groupIds[i..<min(i + batchSize, groupIds.count)])
                let groupSnapshot = try await db.collection("Groups")
                    .whereField(FieldPath.documentID(), in: batch)
                    .getDocuments()
                
                let batchGroups = try groupSnapshot.documents.map { try $0.data(as: GroupModel.self) }
                groups.append(contentsOf: batchGroups)
            }
            
            // 업데이트 시간 기준으로 정렬
            groups.sort { ($0.updatedAt) > ($1.updatedAt) }
            
            return .success(groups)
            
        } catch {
            return .failure(error)
        }
    }
    
    /// 그룹 상세 정보 조회 (클라이언트에서 직접 처리)
    /// - Parameters:
    ///   - groupId: 조회할 그룹 ID
    /// - Returns: 그룹 상세 정보 또는 에러
    func getGroupDetails(groupId: String) async -> Result<GroupModel, Error> {
        guard let currentUser = authService.getCurrentUser() else {
            return .failure(NSError(domain: "GroupService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자가 로그인되어 있지 않습니다."]))
        }
        
        do {
            let groupSnapshot = try await db.collection("Groups").document(groupId).getDocument()
            
            guard groupSnapshot.exists else {
                return .failure(NSError(domain: "GroupService", code: 404, userInfo: [NSLocalizedDescriptionKey: "그룹을 찾을 수 없습니다."]))
            }
            
            let group = try groupSnapshot.data(as: GroupModel.self)
            
            // 비공개 그룹인 경우 멤버인지 확인
            if group.isPrivate {
                let memberSnapshot = try await db.collection("Groups").document(groupId).collection("members")
                    .whereField("userId", isEqualTo: currentUser.uid)
                    .getDocuments()
                
                if memberSnapshot.documents.isEmpty {
                    return .failure(NSError(domain: "GroupService", code: 403, userInfo: [NSLocalizedDescriptionKey: "비공개 그룹에 접근할 수 없습니다."]))
                }
            }
            
            return .success(group)
            
        } catch {
            return .failure(error)
        }
    }
    
    /// 그룹 멤버 목록 조회 (클라이언트에서 직접 처리)
    /// - Parameters:
    ///   - groupId: 조회할 그룹 ID
    /// - Returns: 그룹 멤버 목록 또는 에러
    func getGroupMembers(groupId: String) async -> Result<[GroupMember], Error> {
        guard let currentUser = authService.getCurrentUser() else {
            return .failure(NSError(domain: "GroupService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자가 로그인되어 있지 않습니다."]))
        }
        
        do {
            // 사용자가 그룹 멤버인지 확인
            let userMemberSnapshot = try await db.collection("Groups").document(groupId).collection("members")
                .whereField("userId", isEqualTo: currentUser.uid)
                .getDocuments()
            
            if userMemberSnapshot.documents.isEmpty {
                return .failure(NSError(domain: "GroupService", code: 403, userInfo: [NSLocalizedDescriptionKey: "그룹 멤버만 접근할 수 있습니다."]))
            }
            
            let memberSnapshot = try await db.collection("Groups").document(groupId).collection("members")
                .order(by: "joinedAt")
                .getDocuments()
            
            let members = try memberSnapshot.documents.map { try $0.data(as: GroupMember.self) }
            return .success(members)
            
        } catch {
            return .failure(error)
        }
    }
    
    /// 그룹 초대 목록 조회 (클라이언트에서 직접 처리)
    /// - Parameters:
    ///   - groupId: 조회할 그룹 ID
    /// - Returns: 그룹 초대 목록 또는 에러
    func getGroupInvitations(groupId: String) async -> Result<[GroupInvitation], Error> {
        do {
            let invitationSnapshot = try await db.collection("GroupInvitations")
                .whereField("groupId", isEqualTo: groupId)
                .order(by: "invitedAt", descending: true) // 최신 초대가 위로 오도록 정렬
                .getDocuments()
            
            let invitations = try invitationSnapshot.documents.map { try $0.data(as: GroupInvitation.self) }
            return .success(invitations)
            
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - User Search (백엔드 API 사용)
    
    /// 사용자 검색 (이름으로)
    /// - Parameters:
    ///   - query: 검색 쿼리
    /// - Returns: 검색된 사용자 목록 또는 에러
    func searchUsers(query: String) async -> Result<[User], Error> {
        do {
            let data: [String: Any] = ["query": query]
            let result = try await functions.httpsCallable("searchUsers").call(data)
            
            if let resultData = result.data as? [String: Any],
               let usersData = resultData["users"] as? [[String: Any]] {
                let users = try usersData.map { userData in
                    let jsonData = try JSONSerialization.data(withJSONObject: userData)
                    return try JSONDecoder().decode(User.self, from: jsonData)
                }
                return .success(users)
            } else {
                return .failure(NSError(domain: "GroupService", code: 500, userInfo: [NSLocalizedDescriptionKey: "사용자 검색에 실패했습니다."]))
            }
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Group Invitations (백엔드 API 사용 - 복잡한 로직 포함)
    
    /// 그룹에 사용자 초대
    /// - Parameters:
    ///   - groupId: 초대할 그룹 ID
    ///   - userId: 초대받을 사용자 ID
    /// - Returns: 초대 성공 여부 또는 에러
    func inviteUserToGroup(groupId: String, userId: String) async -> Result<Bool, Error> {
        do {
            let data: [String: Any] = [
                "groupId": groupId,
                "userId": userId
            ]
            let result = try await functions.httpsCallable("inviteUserToGroup").call(data)
            
            if let resultData = result.data as? [String: Any],
               let success = resultData["success"] as? Bool {
                return .success(success)
            } else {
                return .failure(NSError(domain: "GroupService", code: 500, userInfo: [NSLocalizedDescriptionKey: "초대 전송에 실패했습니다."]))
            }
        } catch {
            return .failure(error)
        }
    }
    
    /// 사용자의 그룹 초대 목록 조회 (클라이언트에서 직접 처리)
    /// - Parameters:
    ///   - userId: 조회할 사용자 ID
    /// - Returns: 사용자의 초대 목록 또는 에러
    func getUserInvitations(userId: String) async -> Result<[GroupInvitation], Error> {
        do {
            let snapshot = try await db.collection("GroupInvitations")
                .whereField("invitedUser", isEqualTo: userId)
                .whereField("status", isEqualTo: "pending")
                .order(by: "invitedAt", descending: true)
                .getDocuments()
            
            let invitations = try snapshot.documents.map { try $0.data(as: GroupInvitation.self) }
            return .success(invitations)
        } catch {
            return .failure(error)
        }
    }
    
    /// 그룹 초대 응답 (수락/거절) - 백엔드 API 사용
    /// - Parameters:
    ///   - invitationId: 응답할 초대 ID
    ///   - accept: 수락 여부 (true: 수락, false: 거절)
    /// - Returns: 응답 처리 성공 여부 또는 에러
    func respondToInvitation(invitationId: String, accept: Bool) async -> Result<Bool, Error> {
        do {
            let data: [String: Any] = [
                "invitationId": invitationId,
                "accept": accept
            ]
            let result = try await functions.httpsCallable("respondToInvitation").call(data)
            
            if let resultData = result.data as? [String: Any],
               let success = resultData["success"] as? Bool {
                return .success(success)
            } else {
                return .failure(NSError(domain: "GroupService", code: 500, userInfo: [NSLocalizedDescriptionKey: "초대 응답에 실패했습니다."]))
            }
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Group Goals (클라이언트에서 직접 처리)
    
    /// 그룹 목표 생성
    /// - Parameters:
    ///   - groupId: 목표를 생성할 그룹 ID
    ///   - title: 목표 제목
    ///   - description: 목표 설명 (선택사항)
    ///   - goalType: 목표 유형
    ///   - targetValue: 목표 수치
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    ///   - repeatType: 반복 유형 (선택사항)
    ///   - repeatCount: 반복 횟수 (선택사항)
    /// - Returns: 생성된 그룹 목표 또는 에러
    func createGroupGoal(
        groupId: String,
        title: String,
        description: String?,
        goalType: GroupGoalType,
        targetValue: Double,
        startDate: Date,
        endDate: Date,
        repeatType: String? = nil,
        repeatCount: Int? = nil
    ) async -> Result<GroupGoal, Error> {
        guard let currentUser = authService.getCurrentUser() else {
            return .failure(NSError(domain: "GroupService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자가 로그인되어 있지 않습니다."]))
        }
        
        do {
            // 사용자가 그룹 멤버인지 확인
            let memberSnapshot = try await db.collection("Groups").document(groupId).collection("members")
                .whereField("userId", isEqualTo: currentUser.uid)
                .getDocuments()
            
            if memberSnapshot.documents.isEmpty {
                return .failure(NSError(domain: "GroupService", code: 403, userInfo: [NSLocalizedDescriptionKey: "그룹 멤버만 목표를 생성할 수 있습니다."]))
            }
            
            var goalData: [String: Any] = [
                "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
                "description": description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                "goalType": goalType.rawValue,
                "targetValue": targetValue,
                "unit": goalType.defaultUnit,
                "startDate": Timestamp(date: startDate),
                "endDate": Timestamp(date: endDate),
                "createdBy": currentUser.uid,
                "createdAt": Timestamp(date: Date()),
                "isActive": true,
                "status": GroupGoalStatus.active.rawValue,
                "currentProgress": [:]
            ]
            
            // 반복 정보 추가
            if let repeatType = repeatType {
                goalData["repeatType"] = repeatType
            }
            if let repeatCount = repeatCount {
                goalData["repeatCount"] = repeatCount
            }
            
            // 반복 목표인 경우 currentRepeatCycle을 1로 설정
            if repeatType != nil && repeatType != "none" {
                goalData["currentRepeatCycle"] = 1
            }
            
            let goalRef = try await db.collection("Groups").document(groupId).collection("goals").addDocument(data: goalData)
            let snapshot = try await goalRef.getDocument()
            let goal = try snapshot.data(as: GroupGoal.self)
            return .success(goal)
            
        } catch {
            return .failure(error)
        }
    }
    
    /// 그룹의 목표 목록 조회 (활성 + 완료된 목표 포함)
    /// - Parameters:
    ///   - groupId: 조회할 그룹 ID
    /// - Returns: 그룹의 목표 목록 또는 에러
    func getGroupGoals(groupId: String) async -> Result<[GroupGoal], Error> {
        guard let currentUser = authService.getCurrentUser() else {
            return .failure(NSError(domain: "GroupService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자가 로그인되어 있지 않습니다."]))
        }
        
        do {
            // 사용자가 그룹 멤버인지 확인
            let memberSnapshot = try await db.collection("Groups").document(groupId).collection("members")
                .whereField("userId", isEqualTo: currentUser.uid)
                .getDocuments()
            
            if memberSnapshot.documents.isEmpty {
                return .failure(NSError(domain: "GroupService", code: 403, userInfo: [NSLocalizedDescriptionKey: "그룹 멤버만 접근할 수 있습니다."]))
            }
            
            // 활성 목표와 완료된 목표 모두 가져오기
            let goalSnapshot = try await db.collection("Groups").document(groupId).collection("goals")
                .whereField("status", in: ["active", "completed"])
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            let goals = try goalSnapshot.documents.map { try $0.data(as: GroupGoal.self) }
            return .success(goals)
            
        } catch {
            return .failure(error)
        }
    }
    
    /// 사용자의 그룹 목표 진행률 업데이트
    /// - Parameters:
    /// - groupId: 그룹 ID
    /// - goalId: 목표 ID
    /// - progress: 사용자의 새로운 진행 값
    /// - Returns: 성공 또는 실패
    func updateGroupGoalProgress(groupId: String, goalId: String, progress: Double) async -> Result<Bool, Error> {
        guard let currentUser = authService.getCurrentUser() else {
            return .failure(NSError(domain: "GroupService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자가 로그인되어 있지 않습니다."]))
        }

        do {
            let goalRef = db.collection("Groups").document(groupId).collection("goals").document(goalId)
            
            // Firestore 트랜잭션을 사용하여 currentProgress를 안전하게 업데이트
            try await db.runTransaction { (transaction, errorPointer) -> Any? in
                let goalDocument: DocumentSnapshot
                do {
                    try goalDocument = transaction.getDocument(goalRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }

                guard var goal = try? goalDocument.data(as: GroupGoal.self) else {
                    let error = NSError(domain: "AppError", code: 0, userInfo: [NSLocalizedDescriptionKey: "목표 데이터를 디코딩하는데 실패했습니다."])
                    errorPointer?.pointee = error
                    return nil
                }

                // currentProgress 업데이트
                goal.currentProgress[currentUser.uid] = progress
                
                // 업데이트된 데이터로 문서 업데이트
                do {
                    try transaction.setData(from: goal, forDocument: goalRef)
                } catch let setDataError as NSError {
                    errorPointer?.pointee = setDataError
                    return nil
                }
                return nil
            }
            print("✅ [GroupService] Successfully updated progress for goal \(goalId) in group \(groupId) for user \(currentUser.uid) to \(progress)")
            return .success(true)
        } catch {
            print("⛔️ [GroupService] Error updating goal progress: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    /// 그룹 목표 삭제 (목표 생성자만 가능)
    /// - Parameters:
    ///   - goalId: 삭제할 목표 ID
    ///   - groupId: 그룹 ID
    /// - Returns: 삭제 성공 여부 또는 에러
    func deleteGroupGoal(goalId: String, groupId: String) async -> Result<Bool, Error> {
        guard let currentUser = authService.getCurrentUser() else {
            return .failure(NSError(domain: "GroupService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자가 로그인되어 있지 않습니다."]))
        }
        
        do {
            let goalRef = db.collection("Groups").document(groupId).collection("goals").document(goalId)
            let goalSnapshot = try await goalRef.getDocument()
            
            guard goalSnapshot.exists else {
                return .failure(NSError(domain: "GroupService", code: 404, userInfo: [NSLocalizedDescriptionKey: "목표를 찾을 수 없습니다."]))
            }
            
            let goal = try goalSnapshot.data(as: GroupGoal.self)
            
            // 목표 생성자인지 확인
            if goal.createdBy != currentUser.uid {
                return .failure(NSError(domain: "GroupService", code: 403, userInfo: [NSLocalizedDescriptionKey: "목표 생성자만 삭제할 수 있습니다."]))
            }
            
            // 목표 삭제 (실제로는 isActive를 false로 변경)
            try await goalRef.updateData([
                "isActive": false,
                "status": GroupGoalStatus.deleted.rawValue,
                "deletedAt": Timestamp(date: Date())
            ])
            
            return .success(true)
            
        } catch {
            return .failure(error)
        }
    }
    
    /// 그룹 목표 수정 (목표 생성자만 가능)
    /// - Parameters:
    ///   - goalId: 수정할 목표 ID
    ///   - groupId: 그룹 ID
    ///   - title: 수정된 목표 제목
    ///   - description: 수정된 목표 설명
    ///   - targetValue: 수정된 목표 수치
    ///   - endDate: 수정된 종료일
    /// - Returns: 수정 성공 여부 또는 에러
    func updateGroupGoal(
        goalId: String,
        groupId: String,
        title: String,
        description: String?,
        targetValue: Double,
        endDate: Date
    ) async -> Result<Bool, Error> {
        guard let currentUser = authService.getCurrentUser() else {
            return .failure(NSError(domain: "GroupService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자가 로그인되어 있지 않습니다."]))
        }
        
        print("🔄 [GroupService] Updating goal: \(goalId) in group: \(groupId)")
        print("📊 [GroupService] Update data - title: \(title), targetValue: \(targetValue), endDate: \(endDate)")
        
        do {
            let goalRef = db.collection("Groups").document(groupId).collection("goals").document(goalId)
            let goalSnapshot = try await goalRef.getDocument()
            
            guard goalSnapshot.exists else {
                print("❌ [GroupService] Goal not found: \(goalId)")
                return .failure(NSError(domain: "GroupService", code: 404, userInfo: [NSLocalizedDescriptionKey: "목표를 찾을 수 없습니다."]))
            }
            
            let goal = try goalSnapshot.data(as: GroupGoal.self)
            print("📋 [GroupService] Current goal data - title: \(goal.title), targetValue: \(goal.targetValue)")
            
            // 목표 생성자인지 확인
            if goal.createdBy != currentUser.uid {
                print("🚫 [GroupService] Permission denied. Goal creator: \(goal.createdBy), Current user: \(currentUser.uid)")
                return .failure(NSError(domain: "GroupService", code: 403, userInfo: [NSLocalizedDescriptionKey: "목표 생성자만 수정할 수 있습니다."]))
            }
            
            // 목표 정보 업데이트
            let updateData: [String: Any] = [
                "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
                "description": description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                "targetValue": targetValue,
                "endDate": Timestamp(date: endDate),
                "updatedAt": Timestamp(date: Date()) // 업데이트 시간 추가
            ]
            
            print("📝 [GroupService] Sending update data to Firestore: \(updateData)")
            try await goalRef.updateData(updateData)
            print("✅ [GroupService] Goal updated successfully: \(goalId)")
            
            return .success(true)
            
        } catch {
            print("❌ [GroupService] Error updating goal: \(error)")
            return .failure(error)
        }
    }
    
    /// 그룹 통계 조회 (백엔드 API 사용 - 복잡한 계산 로직)
    /// - Parameters:
    ///   - groupId: 조회할 그룹 ID
    /// - Returns: 그룹 통계 정보 또는 에러
    func getGroupStatistics(groupId: String) async -> Result<GroupStatistics, Error> {
        do {
            let data: [String: Any] = ["groupId": groupId]
            let result = try await functions.httpsCallable("getGroupStatistics").call(data)
            
            if let statisticsData = result.data as? [String: Any] {
                let jsonData = try JSONSerialization.data(withJSONObject: statisticsData)
                let statistics = try JSONDecoder().decode(GroupStatistics.self, from: jsonData)
                return .success(statistics)
            } else {
                return .failure(NSError(domain: "GroupService", code: 500, userInfo: [NSLocalizedDescriptionKey: "통계 조회에 실패했습니다."]))
            }
        } catch {
            return .failure(error)
        }
    }
    
    /// 반복 목표 수동 갱신 (테스팅용) - 백엔드 API 사용
    /// - Returns: 갱신 결과 또는 에러
    func manualRenewRepeatingGoals() async -> Result<[String: Any], Error> {
        do {
            print("🔄 [GroupService] Calling manual renew repeating goals...")
            let result = try await functions.httpsCallable("manualRenewRepeatingGoals").call()
            
            if let resultData = result.data as? [String: Any] {
                print("✅ [GroupService] Manual renew completed: \(resultData)")
                return .success(resultData)
            } else {
                print("⛔️ [GroupService] Invalid response format from manual renew")
                return .failure(NSError(domain: "GroupService", code: 500, userInfo: [NSLocalizedDescriptionKey: "반복 목표 갱신에 실패했습니다."]))
            }
        } catch {
            print("⛔️ [GroupService] Error in manual renew: \(error)")
            return .failure(error)
        }
    }
    
    /// 목표 진행률 업데이트 (백엔드 API 사용)
    /// - Parameters:
    ///   - goalId: 목표 ID
    ///   - groupId: 그룹 ID
    ///   - progress: 새로운 진행률
    /// - Returns: 업데이트 결과
    func updateGoalProgress(goalId: String, groupId: String, progress: Double) async -> Result<[String: Any], Error> {
        do {
            print("🔄 [GroupService] Updating goal progress: \(progress)")
            let data: [String: Any] = [
                "goalId": goalId,
                "groupId": groupId,
                "progress": progress
            ]
            
            let result = try await functions.httpsCallable("updateGoalProgress").call(data)
            
            if let resultData = result.data as? [String: Any] {
                print("✅ [GroupService] Goal progress updated: \(resultData)")
                return .success(resultData)
            } else {
                print("⛔️ [GroupService] Invalid response format from progress update")
                return .failure(NSError(domain: "GroupService", code: 500, userInfo: [NSLocalizedDescriptionKey: "진행률 업데이트에 실패했습니다."]))
            }
        } catch {
            print("⛔️ [GroupService] Error updating goal progress: \(error)")
            return .failure(error)
        }
    }
    
    /// 목표 완료 상태 확인 (백엔드 API 사용)
    /// - Parameters:
    ///   - groupId: 그룹 ID
    /// - Returns: 확인 결과
    func checkGoalCompletion(groupId: String) async -> Result<[String: Any], Error> {
        do {
            print("🔄 [GroupService] Checking goal completion for group: \(groupId)")
            let data: [String: Any] = ["groupId": groupId]
            
            let result = try await functions.httpsCallable("checkGoalCompletion").call(data)
            
            if let resultData = result.data as? [String: Any] {
                print("✅ [GroupService] Goal completion check completed: \(resultData)")
                return .success(resultData)
            } else {
                print("⛔️ [GroupService] Invalid response format from goal completion check")
                return .failure(NSError(domain: "GroupService", code: 500, userInfo: [NSLocalizedDescriptionKey: "목표 완료 확인에 실패했습니다."]))
            }
        } catch {
            print("⛔️ [GroupService] Error checking goal completion: \(error)")
            return .failure(error)
        }
    }
    
    // MARK: - Group Management (클라이언트에서 직접 처리)
    
    /// 그룹 정보 업데이트 (관리자만 가능)
    /// - Parameters:
    ///   - group: 업데이트할 그룹 정보
    /// - Returns: 업데이트 성공 여부 또는 에러
    func updateGroup(_ group: GroupModel) async -> Result<GroupModel, Error> {
        guard let currentUser = authService.getCurrentUser() else {
            return .failure(NSError(domain: "GroupService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자가 로그인되어 있지 않습니다."]))
        }
        
        guard let groupId = group.id else {
            return .failure(NSError(domain: "GroupService", code: 400, userInfo: [NSLocalizedDescriptionKey: "그룹 ID가 필요합니다."]))
        }
        
        do {
            // 사용자가 그룹 관리자인지 확인
            let memberSnapshot = try await db.collection("Groups").document(groupId).collection("members")
                .whereField("userId", isEqualTo: currentUser.uid)
                .whereField("role", isEqualTo: "admin")
                .getDocuments()
            
            if memberSnapshot.documents.isEmpty {
                return .failure(NSError(domain: "GroupService", code: 403, userInfo: [NSLocalizedDescriptionKey: "그룹 관리자만 그룹 정보를 수정할 수 있습니다."]))
            }
            
            let updateData: [String: Any] = [
                "name": group.name.trimmingCharacters(in: .whitespacesAndNewlines),
                "description": group.description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                "isPrivate": group.isPrivate,
                "tags": group.tags,
                "updatedAt": Timestamp(date: Date())
            ]
            
            try await db.collection("Groups").document(groupId).updateData(updateData)
            
            // 업데이트된 그룹 정보 조회
            let snapshot = try await db.collection("Groups").document(groupId).getDocument()
            let updatedGroup = try snapshot.data(as: GroupModel.self)
            return .success(updatedGroup)
            
        } catch {
            return .failure(error)
        }
    }
    
    /// 그룹 삭제 (관리자만 가능)
    /// - Parameters:
    ///   - groupId: 삭제할 그룹 ID
    /// - Returns: 삭제 성공 여부 또는 에러
    func deleteGroup(groupId: String) async -> Result<Bool, Error> {
        guard let currentUser = authService.getCurrentUser() else {
            return .failure(NSError(domain: "GroupService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자가 로그인되어 있지 않습니다."]))
        }
        
        do {
            // 사용자가 그룹 관리자인지 확인
            let memberSnapshot = try await db.collection("Groups").document(groupId).collection("members")
                .whereField("userId", isEqualTo: currentUser.uid)
                .whereField("role", isEqualTo: "admin")
                .getDocuments()
            
            if memberSnapshot.documents.isEmpty {
                return .failure(NSError(domain: "GroupService", code: 403, userInfo: [NSLocalizedDescriptionKey: "그룹 관리자만 그룹을 삭제할 수 있습니다."]))
            }
            
            // 그룹의 모든 멤버 삭제
            let allMembersSnapshot = try await db.collection("Groups").document(groupId).collection("members").getDocuments()
            for memberDoc in allMembersSnapshot.documents {
                try await memberDoc.reference.delete()
            }
            
            // 그룹의 모든 목표 삭제
            let goalsSnapshot = try await db.collection("Groups").document(groupId).collection("goals").getDocuments()
            for goalDoc in goalsSnapshot.documents {
                try await goalDoc.reference.delete()
            }
            
            // 그룹의 모든 초대 삭제
            let invitationsSnapshot = try await db.collection("GroupInvitations")
                .whereField("groupId", isEqualTo: groupId)
                .getDocuments()
            for invitationDoc in invitationsSnapshot.documents {
                try await invitationDoc.reference.delete()
            }
            
            // 그룹 문서 삭제
            try await db.collection("Groups").document(groupId).delete()
            
            return .success(true)
            
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Group Search (클라이언트에서 직접 처리)
    
    /// 모든 공개 그룹 조회 (검색용)
    /// - Returns: 모든 공개 그룹 목록 또는 에러
    func getAllPublicGroups() async -> Result<[GroupModel], Error> {
        do {
            let groupSnapshot = try await db.collection("Groups")
                .whereField("isPrivate", isEqualTo: false)
                .order(by: "memberCount", descending: true)
                .getDocuments()
            
            let groups = try groupSnapshot.documents.map { try $0.data(as: GroupModel.self) }
            return .success(groups)
            
        } catch {
            return .failure(error)
        }
    }
    
    /// 공개 그룹 검색
    /// - Parameters:
    ///   - query: 검색 키워드
    ///   - tags: 필터링할 태그 배열 (기본값: 빈 배열)
    /// - Returns: 검색된 공개 그룹 목록 또는 에러
    func searchPublicGroups(query: String, tags: [String] = []) async -> Result<[GroupModel], Error> {
        do {
            var groupQuery = db.collection("Groups")
                .whereField("isPrivate", isEqualTo: false)
                .order(by: "memberCount", descending: true)
                .limit(to: 20)
            
            // 태그 필터링
            if !tags.isEmpty {
                groupQuery = groupQuery.whereField("tags", arrayContainsAny: tags)
            }
            
            let groupSnapshot = try await groupQuery.getDocuments()
            var groups = try groupSnapshot.documents.map { try $0.data(as: GroupModel.self) }
            
            // 클라이언트 사이드에서 이름으로 필터링
            if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let searchQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                groups = groups.filter { group in
                    group.name.lowercased().contains(searchQuery)
                }
            }
            
            return .success(groups)
            
        } catch {
            return .failure(error)
        }
    }
    
    /// 그룹의 완료된/보관된 목표 목록 조회
    /// - Parameters:
    ///   - groupId: 조회할 그룹 ID
    ///   - status: 조회할 목표 상태 (completed, archived, deleted)
    /// - Returns: 해당 상태의 목표 목록 또는 에러
    func getGroupGoalsByStatus(groupId: String, status: GroupGoalStatus) async -> Result<[GroupGoal], Error> {
        guard let currentUser = authService.getCurrentUser() else {
            return .failure(NSError(domain: "GroupService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자가 로그인되어 있지 않습니다."]))
        }
        
        do {
            // 사용자가 그룹 멤버인지 확인
            let memberSnapshot = try await db.collection("Groups").document(groupId).collection("members")
                .whereField("userId", isEqualTo: currentUser.uid)
                .getDocuments()
            
            if memberSnapshot.documents.isEmpty {
                return .failure(NSError(domain: "GroupService", code: 403, userInfo: [NSLocalizedDescriptionKey: "그룹 멤버만 접근할 수 있습니다."]))
            }
            
            let goalSnapshot = try await db.collection("Groups").document(groupId).collection("goals")
                .whereField("status", isEqualTo: status.rawValue)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            let goals = try goalSnapshot.documents.map { try $0.data(as: GroupGoal.self) }
            return .success(goals)
            
        } catch {
            return .failure(error)
        }
    }
} 
