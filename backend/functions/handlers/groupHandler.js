const { initializeApp, getApps } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { logger } = require('firebase-functions');
const { notifyGroupMembersAboutNewGoal } = require('./notificationHandler');

// Initialize Firebase Admin if not already initialized
if (getApps().length === 0) {
    initializeApp();
}

const db = getFirestore();
const admin = require('firebase-admin');

/**
 * 사용자를 그룹에 초대
 * @param {Object} request - Firebase Functions 요청 객체
 * @param {string} request.data.groupId - 초대할 그룹 ID
 * @param {string} request.data.userId - 초대받을 사용자 ID
 * @param {string} request.auth.uid - 초대하는 사용자 ID
 * @returns {Object} 초대 성공 여부
 */
exports.inviteUserToGroup = async (request) => {
    try {
        const { groupId, userId: invitedUserId } = request.data;
        const userId = request.auth?.uid;

        if (!userId) {
            throw new Error('User not authenticated');
        }

        if (!groupId || !invitedUserId) {
            throw new Error('Group ID and user ID are required');
        }

        // 그룹 존재 확인
        const groupDoc = await db.collection('Groups').doc(groupId).get();
        if (!groupDoc.exists) {
            throw new Error('Group not found');
        }

        const groupData = groupDoc.data();

        // 초대하는 사용자가 그룹 멤버인지 확인
        const inviterMemberSnapshot = await db.collection('Groups').doc(groupId).collection('members')
            .where('userId', '==', userId)
            .get();

        if (inviterMemberSnapshot.empty) {
            throw new Error('Only group members can invite others');
        }

        // 이미 초대된 사용자인지 확인
        const existingInvitation = await db.collection('GroupInvitations')
            .where('groupId', '==', groupId)
            .where('invitedUser', '==', invitedUserId)
            .where('status', '==', 'pending')
            .get();

        if (!existingInvitation.empty) {
            throw new Error('User already invited');
        }

        // 이미 그룹 멤버인지 확인
        const existingMember = await db.collection('Groups').doc(groupId).collection('members')
            .where('userId', '==', invitedUserId)
            .get();

        if (!existingMember.empty) {
            throw new Error('User is already a group member');
        }

        // Get inviter info from Firestore first, fallback to Auth
        let inviterName = 'Unknown';
        try {
            const userDoc = await db.collection('Users').doc(userId).get();
            if (userDoc.exists) {
                const userData = userDoc.data();
                inviterName = userData.name || 'Unknown';
            } else {
                // Fallback to Firebase Auth
                const userRecord = await getAuth().getUser(userId);
                inviterName = userRecord.displayName || 'Unknown';
            }
        } catch (error) {
            console.log('Failed to get inviter name, using Unknown:', error);
        }

        // 초대 생성
        const invitationData = {
            groupId: groupId,
            groupName: groupData.name,
            invitedBy: userId,
            invitedByName: inviterName,
            invitedUser: invitedUserId,
            invitedAt: admin.firestore.FieldValue.serverTimestamp(),
            status: 'pending'
        };

        await db.collection('GroupInvitations').add(invitationData);

        logger.info(`User ${invitedUserId} invited to group ${groupId} by ${userId}`);
        return { success: true, message: 'Invitation sent successfully' };

    } catch (error) {
        logger.error('Error inviting user to group:', error);
        throw new Error(`Failed to invite user: ${error.message}`);
    }
};

/**
 * 그룹 초대에 응답 (수락/거절)
 * @param {Object} request - Firebase Functions 요청 객체
 * @param {string} request.data.invitationId - 응답할 초대 ID
 * @param {boolean} request.data.accept - 수락 여부
 * @param {string} request.auth.uid - 인증된 사용자 ID
 * @returns {Object} 응답 처리 결과
 */
exports.respondToInvitation = async (request) => {
    try {
        const { invitationId, accept } = request.data;
        const userId = request.auth?.uid;

        if (!userId) {
            throw new Error('User not authenticated');
        }

        if (!invitationId || typeof accept !== 'boolean') {
            throw new Error('Invitation ID and accept status are required');
        }

        const invitationRef = db.collection('GroupInvitations').doc(invitationId);
        const invitationDoc = await invitationRef.get();

        if (!invitationDoc.exists) {
            throw new Error('Invitation not found');
        }

        const invitationData = invitationDoc.data();

        if (invitationData.invitedUser !== userId) {
            throw new Error('Access denied');
        }

        if (invitationData.status !== 'pending') {
            throw new Error('Invitation already responded to');
        }

        const status = accept ? 'accepted' : 'declined';

        // 초대 상태 업데이트
        await invitationRef.update({
            status,
            respondedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // 수락한 경우 그룹 멤버로 추가
        if (accept) {
            // Get user info from Firestore first, fallback to Auth
            let userName = 'Unknown';
            try {
                const userDoc = await db.collection('Users').doc(userId).get();
                if (userDoc.exists) {
                    const userData = userDoc.data();
                    userName = userData.name || 'Unknown';
                } else {
                    // Fallback to Firebase Auth
                    const userRecord = await getAuth().getUser(userId);
                    userName = userRecord.displayName || 'Unknown';
                }
            } catch (error) {
                console.log('Failed to get user name, using Unknown:', error);
            }

            const memberData = {
                userId: userId,
                userName: userName,
                joinedAt: admin.firestore.FieldValue.serverTimestamp(),
                role: 'member'
            };

            await db.collection('Groups').doc(invitationData.groupId).collection('members').add(memberData);

            // 그룹 멤버 수 증가
            await db.collection('Groups').doc(invitationData.groupId).update({
                memberCount: admin.firestore.FieldValue.increment(1),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }

        logger.info(`Invitation ${invitationId} ${status} by user ${userId}`);
        return { success: true, message: `Invitation ${status} successfully` };

    } catch (error) {
        logger.error('Error responding to invitation:', error);
        throw new Error(`Failed to respond to invitation: ${error.message}`);
    }
};

/**
 * 그룹 통계 조회 (복잡한 계산 로직)
 * @param {Object} request - Firebase Functions 요청 객체
 * @param {string} request.data.groupId - 조회할 그룹 ID
 * @param {string} request.auth.uid - 인증된 사용자 ID
 * @returns {Object} 그룹 통계 정보
 */
exports.getGroupStatistics = async (request) => {
    try {
        const { groupId } = request.data;
        const userId = request.auth?.uid;

        if (!userId) {
            throw new Error('User not authenticated');
        }

        if (!groupId) {
            throw new Error('Group ID is required');
        }

        // 그룹 기본 정보 조회
        const groupDoc = await db.collection('Groups').doc(groupId).get();
        if (!groupDoc.exists) {
            throw new Error('Group not found');
        }
        const groupData = groupDoc.data();
        
        // 비공개 그룹인 경우에만 멤버인지 확인
        if (groupData.isPrivate) {
            const memberSnapshot = await db.collection('Groups').doc(groupId).collection('members')
                .where('userId', '==', userId)
                .get();

            if (memberSnapshot.empty) {
                throw new Error('Access denied. Not a member of private group.');
            }
        }

        // 그룹 멤버 수
        const allMembersSnapshot = await db.collection('Groups').doc(groupId).collection('members')
            .get();

        const totalMembers = allMembersSnapshot.size;

        // 활성 목표 수
        const activeGoalsSnapshot = await db.collection('Groups').doc(groupId).collection('goals')
            .where('isActive', '==', true)
            .get();

        const totalActiveGoals = activeGoalsSnapshot.size;

        // 완료된 목표 수 (간단한 예시 - 실제로는 더 복잡한 로직 필요)
        const completedGoalsSnapshot = await db.collection('Groups').doc(groupId).collection('goals')
            .where('isActive', '==', false)
            .get();

        const totalCompletedGoals = completedGoalsSnapshot.size;

        // 상위 수행자 (예시 데이터 - 실제로는 운동 데이터 기반 계산)
        const topPerformers = allMembersSnapshot.docs.slice(0, 5).map(doc => {
            const memberData = doc.data();
            return {
                userId: memberData.userId,
                userName: memberData.userName,
                userProfileImageUrl: memberData.userProfileImageUrl || '',
                workoutCount: Math.floor(Math.random() * 50), // 실제로는 운동 데이터 기반
                totalDuration: Math.floor(Math.random() * 1000), // 실제로는 운동 데이터 기반
                totalWeight: Math.floor(Math.random() * 5000), // 실제로는 운동 데이터 기반
                rank: 0 // 나중에 정렬 후 설정
            };
        }).sort((a, b) => b.workoutCount - a.workoutCount)
        .map((performer, index) => ({ ...performer, rank: index + 1 }));

        const statistics = {
            groupId: groupId,
            totalWorkouts: Math.floor(Math.random() * 100), // 실제로는 운동 데이터 기반
            totalDuration: Math.floor(Math.random() * 1000), // 실제로는 운동 데이터 기반 (분)
            totalWeight: Math.floor(Math.random() * 10000), // 실제로는 운동 데이터 기반 (kg)
            averageWorkoutsPerMember: totalMembers > 0 ? Math.floor(Math.random() * 20) : 0,
            topPerformers: topPerformers,
            lastUpdated: new Date()
        };

        return statistics;

    } catch (error) {
        logger.error('Error fetching group statistics:', error);
        throw new Error(`Failed to fetch group statistics: ${error.message}`);
    }
};

/**
 * 사용자 검색 (이름으로)
 * @param {Object} request - Firebase Functions 요청 객체
 * @param {string} request.data.query - 검색 쿼리
 * @param {string} request.auth.uid - 인증된 사용자 ID
 * @returns {Object} 검색된 사용자 목록
 */
exports.searchUsers = async (request) => {
    try {
        const { query } = request.data;
        const userId = request.auth?.uid;

        if (!userId) {
            throw new Error('User not authenticated');
        }

        if (!query || query.trim() === '') {
            throw new Error('Search query is required');
        }

        const searchQuery = query.trim().toLowerCase();

        // Firestore에서 사용자 검색 (이름으로)
        const userSnapshot = await db.collection('Users')
            .where('name', '>=', searchQuery)
            .where('name', '<=', searchQuery + '\uf8ff')
            .limit(20)
            .get();

        const users = userSnapshot.docs
            .map(doc => ({
                uid: doc.id,
                ...doc.data()
            }))
            .filter(user => user.uid !== userId); // 자기 자신 제외

        return { users };

    } catch (error) {
        logger.error('Error searching users:', error);
        throw new Error(`Failed to search users: ${error.message}`);
    }
};

/**
 * 반복 목표 갱신 스케줄러 (매일 00:00에 실행)
 * 반복 설정이 있는 목표들을 확인하여 새로운 주기의 목표를 생성합니다.
 */
exports.renewRepeatingGoals = async () => {
    try {
        logger.info('Starting repeating goals renewal process');
        
        const today = new Date();
        today.setHours(0, 0, 0, 0); // 오늘 00:00:00으로 설정
        
        let renewedGoalsCount = 0;
        let completedGoalsCount = 0;
        
        // 모든 그룹을 순회
        const groupsSnapshot = await db.collection('Groups').get();
        
        for (const groupDoc of groupsSnapshot.docs) {
            const groupId = groupDoc.id;
            
            // 각 그룹의 활성 반복 목표들을 조회
            const goalsSnapshot = await db.collection('Groups').doc(groupId).collection('goals')
                .where('isActive', '==', true)
                .where('repeatType', 'in', ['weekly', 'monthly'])
                .get();
            
            for (const goalDoc of goalsSnapshot.docs) {
                const goalData = goalDoc.data();
                const goalId = goalDoc.id;
                
                // originalEndDate 필드가 undefined인 경우 제거
                if (goalData.originalEndDate === undefined) {
                    delete goalData.originalEndDate;
                }
                
                // 목표 데이터 로그 출력
                logger.info(`Goal data before processing: ${JSON.stringify({
                    goalId,
                    title: goalData.title,
                    repeatType: goalData.repeatType,
                    repeatCount: goalData.repeatCount,
                    currentRepeatCycle: goalData.currentRepeatCycle,
                    endDate: goalData.endDate,
                    hasOriginalEndDate: goalData.originalEndDate !== undefined
                })}`);
                
                try {
                    const result = await processRepeatingGoal(groupId, goalId, goalData, today);
                    if (result === 'renewed') {
                        renewedGoalsCount++;
                    } else if (result === 'completed') {
                        completedGoalsCount++;
                    }
                } catch (error) {
                    logger.error(`Error processing goal ${goalId} in group ${groupId}:`, error);
                }
            }
        }
        
        logger.info(`Repeating goals renewal completed. Renewed: ${renewedGoalsCount}, Completed: ${completedGoalsCount}`);
        return { success: true, renewedGoalsCount, completedGoalsCount };
        
    } catch (error) {
        logger.error('Error in renewRepeatingGoals:', error);
        throw error;
    }
};

/**
 * 개별 반복 목표 처리 (간단 버전)
 * @param {string} groupId - 그룹 ID
 * @param {string} goalId - 목표 ID
 * @param {Object} goalData - 목표 데이터
 * @param {Date} today - 오늘 날짜
 * @returns {string} 처리 결과 ('renewed', 'completed', 'no_action')
 */
async function processRepeatingGoal(groupId, goalId, goalData, today) {
    const {
        title,
        description,
        goalType,
        targetValue,
        unit,
        startDate,
        endDate,
        createdBy,
        repeatType,
        repeatCount,
        currentRepeatCycle = 1
    } = goalData;
    
    // 로그로 어떤 목표를 처리하는지 확인
    logger.info(`Processing goal: ${title} (${goalId}) - repeatType: ${repeatType}, cycle: ${currentRepeatCycle}/${repeatCount}`);
    
    const goalEndDate = endDate.toDate();
    
    // 엔드 데이트가 현재 시각보다 지나가지 않았으면 아무것도 안함
    if (today <= goalEndDate) {
        return 'no_action';
    }
    
    // 반복 타입이 없으면 완료 처리
    if (!repeatType || repeatType === 'none') {
        await db.collection('Groups').doc(groupId).collection('goals').doc(goalId).update({
            isActive: false,
            status: 'completed',
            completedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        return 'completed';
    }
    
    // 반복 횟수가 완료되었으면 완료 처리
    if (currentRepeatCycle >= repeatCount) {
        await db.collection('Groups').doc(groupId).collection('goals').doc(goalId).update({
            isActive: false,
            status: 'completed',
            completedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        return 'completed';
    }
    
    // 새로운 목표 생성
    const nextCycle = currentRepeatCycle + 1;
    let daysDuration = 7; // 기본 7일
    
    if (repeatType === 'weekly') {
        daysDuration = 7;
    } else if (repeatType === 'monthly') {
        daysDuration = 30;
    }
    
    const newStartDate = new Date(goalEndDate);
    newStartDate.setDate(newStartDate.getDate() + 1);
    
    const newEndDate = new Date(newStartDate);
    newEndDate.setDate(newEndDate.getDate() + daysDuration - 1);
    
    // 기존 목표 비활성화
    await db.collection('Groups').doc(groupId).collection('goals').doc(goalId).update({
        isActive: false,
        status: 'archived',
        archivedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // 새로운 목표 생성
    const newGoalData = {
        title: title,
        description: description || '',
        goalType: goalType,
        targetValue: targetValue,
        unit: unit,
        startDate: admin.firestore.Timestamp.fromDate(newStartDate),
        endDate: admin.firestore.Timestamp.fromDate(newEndDate),
        createdBy: createdBy,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isActive: true,
        status: 'active',
        repeatType: repeatType,
        repeatCount: repeatCount,
        currentRepeatCycle: nextCycle,
        currentProgress: {}
    };
    
    logger.info(`Creating new goal data: ${JSON.stringify(newGoalData)}`);
    await db.collection('Groups').doc(groupId).collection('goals').add(newGoalData);
    
    logger.info(`Goal renewed: ${title} (Cycle ${nextCycle}/${repeatCount}) in group ${groupId}`);
    return 'renewed';
}

/**
 * 목표 진행률 업데이트 및 달성 확인
 * @param {Object} request - Firebase Functions 요청 객체
 * @param {string} request.data.goalId - 목표 ID
 * @param {string} request.data.groupId - 그룹 ID
 * @param {number} request.data.progress - 새로운 진행률
 * @param {string} request.auth.uid - 인증된 사용자 ID
 * @returns {Object} 업데이트 결과
 */
exports.updateGoalProgress = async (request) => {
    try {
        const { goalId, groupId, progress } = request.data;
        const userId = request.auth?.uid;

        if (!userId) {
            throw new Error('User not authenticated');
        }

        if (!goalId || !groupId || progress === undefined) {
            throw new Error('Goal ID, group ID, and progress are required');
        }

        // 그룹 멤버 확인
        const memberSnapshot = await db.collection('Groups').doc(groupId).collection('members')
            .where('userId', '==', userId)
            .get();

        if (memberSnapshot.empty) {
            throw new Error('Access denied. Not a group member.');
        }

        // 목표 존재 확인
        const goalRef = db.collection('Groups').doc(groupId).collection('goals').doc(goalId);
        const goalDoc = await goalRef.get();

        if (!goalDoc.exists) {
            throw new Error('Goal not found');
        }

        const goalData = goalDoc.data();

        // 진행률 업데이트
        const updatedProgress = {
            ...goalData.currentProgress,
            [userId]: progress
        };

        await goalRef.update({
            currentProgress: updatedProgress,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // 모든 멤버가 목표를 달성했는지 확인
        const allMembersSnapshot = await db.collection('Groups').doc(groupId).collection('members').get();
        const totalMembers = allMembersSnapshot.size;
        const achievedMembers = Object.values(updatedProgress).filter(p => p >= goalData.targetValue).length;

        // 모든 멤버가 달성한 경우 완료 처리
        if (achievedMembers >= totalMembers && goalData.isActive) {
            await goalRef.update({
                status: 'completed',
                isActive: false,
                completedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            
            logger.info(`Goal ${goalId} completed by all members in group ${groupId}`);
            return { 
                success: true, 
                message: 'Progress updated and goal completed!', 
                goalCompleted: true 
            };
        }

        logger.info(`Progress updated for user ${userId} in goal ${goalId}`);
        return { 
            success: true, 
            message: 'Progress updated successfully', 
            goalCompleted: false 
        };

    } catch (error) {
        logger.error('Error updating goal progress:', error);
        throw new Error(`Failed to update progress: ${error.message}`);
    }
};

/**
 * 목표 상태 확인 및 자동 완료 처리
 * @param {Object} request - Firebase Functions 요청 객체
 * @param {string} request.data.groupId - 그룹 ID
 * @param {string} request.auth.uid - 인증된 사용자 ID
 * @returns {Object} 확인 결과
 */
exports.checkGoalCompletion = async (request) => {
    try {
        const { groupId } = request.data;
        const userId = request.auth?.uid;

        if (!userId) {
            throw new Error('User not authenticated');
        }

        if (!groupId) {
            throw new Error('Group ID is required');
        }

        // 그룹 멤버 확인
        const memberSnapshot = await db.collection('Groups').doc(groupId).collection('members')
            .where('userId', '==', userId)
            .get();

        if (memberSnapshot.empty) {
            throw new Error('Access denied. Not a group member.');
        }

        // 활성 목표들 조회
        const goalsSnapshot = await db.collection('Groups').doc(groupId).collection('goals')
            .where('isActive', '==', true)
            .get();

        const allMembersSnapshot = await db.collection('Groups').doc(groupId).collection('members').get();
        const totalMembers = allMembersSnapshot.size;

        let completedGoalsCount = 0;

        for (const goalDoc of goalsSnapshot.docs) {
            const goalData = goalDoc.data();
            const goalId = goalDoc.id;

            if (goalData.currentProgress) {
                const achievedMembers = Object.values(goalData.currentProgress)
                    .filter(progress => progress >= goalData.targetValue).length;

                // 모든 멤버가 달성한 경우 완료 처리
                if (achievedMembers >= totalMembers) {
                    await db.collection('Groups').doc(groupId).collection('goals').doc(goalId).update({
                        status: 'completed',
                        isActive: false,
                        completedAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                    completedGoalsCount++;
                    logger.info(`Goal ${goalId} auto-completed in group ${groupId}`);
                }
            }
        }

        return { 
            success: true, 
            completedGoalsCount,
            message: `${completedGoalsCount} goals auto-completed` 
        };

    } catch (error) {
        logger.error('Error checking goal completion:', error);
        throw new Error(`Failed to check goal completion: ${error.message}`);
    }
};