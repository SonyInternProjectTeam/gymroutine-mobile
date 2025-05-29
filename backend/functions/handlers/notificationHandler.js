const { initializeApp, getApps } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { logger } = require('firebase-functions');

// Initialize Firebase Admin if not already initialized
if (getApps().length === 0) {
    initializeApp();
}

const db = getFirestore();
const admin = require('firebase-admin');

/**
 * 알림 생성 헬퍼 함수
 * @param {string} userId - 알림을 받을 사용자 ID
 * @param {string} type - 알림 타입
 * @param {string} title - 알림 제목
 * @param {string} message - 알림 메시지
 * @param {Object} metadata - 추가 메타데이터
 */
async function createNotification(userId, type, title, message, metadata = {}) {
    try {
        const notificationData = {
            userId: userId,
            type: type,
            title: title,
            message: message,
            metadata: metadata,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        };
        
        await db.collection('Notifications').add(notificationData);
        logger.info(`Notification created for user ${userId}: ${title}`);
    } catch (error) {
        logger.error(`Failed to create notification for user ${userId}:`, error);
    }
}

/**
 * 팔로우 알림 생성
 * @param {string} followedUserId - 팔로우 당한 사용자 ID
 * @param {string} followerUserId - 팔로우 한 사용자 ID
 */
async function notifyUserAboutNewFollower(followedUserId, followerUserId) {
    try {
        // 팔로워 정보 조회
        let followerName = 'Unknown';
        try {
            const followerDoc = await db.collection('Users').doc(followerUserId).get();
            if (followerDoc.exists) {
                followerName = followerDoc.data().name || 'Unknown';
            }
        } catch (error) {
            logger.warn('Failed to get follower name:', error);
        }
        
        await createNotification(
            followedUserId,
            'new_follower',
            '新しいフォロワー',
            `${followerName}さんがあなたをフォローしました`,
            {
                followerId: followerUserId,
                followerName: followerName
            }
        );
        
    } catch (error) {
        logger.error('Error creating follow notification:', error);
    }
}

/**
 * 사용자 알림 조회
 * @param {Object} request - Firebase Functions 요청 객체
 * @param {string} request.auth.uid - 인증된 사용자 ID
 * @returns {Object} 사용자의 알림 목록
 */
exports.getUserNotifications = async (request) => {
    try {
        const userId = request.auth?.uid;
        logger.info(`[getUserNotifications] Function called for user: ${userId}`);

        if (!userId) {
            logger.error('[getUserNotifications] User not authenticated');
            throw new Error('User not authenticated');
        }

        logger.info(`[getUserNotifications] Starting to fetch notifications for user: ${userId}`);

        // 사용자의 알림 조회 (최신 순, 최대 50개)
        const notificationsQuery = db.collection('Notifications')
            .where('userId', '==', userId)
            .orderBy('createdAt', 'desc')
            .limit(50);

        logger.info(`[getUserNotifications] Executing Firestore query...`);
        const notificationsSnapshot = await notificationsQuery.get();

        logger.info(`[getUserNotifications] Query completed. Found ${notificationsSnapshot.docs.length} documents`);

        const notifications = [];
        
        for (const doc of notificationsSnapshot.docs) {
            try {
                const data = doc.data();
                logger.info(`[getUserNotifications] Processing notification ${doc.id}`);
                
                const notification = {
                    id: doc.id,
                    ...data,
                    createdAt: data.createdAt?.toDate() || new Date()
                };
                
                notifications.push(notification);
                logger.info(`[getUserNotifications] Successfully processed notification ${doc.id}`);
            } catch (docError) {
                logger.error(`[getUserNotifications] Error processing document ${doc.id}:`, docError);
                // Continue with other notifications
            }
        }

        logger.info(`[getUserNotifications] Successfully processed ${notifications.length} notifications`);
        logger.info(`[getUserNotifications] Returning response...`);
        
        return { 
            success: true,
            notifications: notifications,
            count: notifications.length
        };

    } catch (error) {
        logger.error('[getUserNotifications] Function error:', error);
        logger.error(`[getUserNotifications] Error type: ${typeof error}`);
        logger.error(`[getUserNotifications] Error message: ${error.message}`);
        logger.error(`[getUserNotifications] Error stack: ${error.stack}`);
        
        throw new Error(`Failed to fetch notifications: ${error.message}`);
    }
};

/**
 * 알림을 읽음으로 표시
 * @param {Object} request - Firebase Functions 요청 객체
 * @param {string} request.data.notificationId - 알림 ID
 * @param {string} request.auth.uid - 인증된 사용자 ID
 * @returns {Object} 업데이트 결과
 */
exports.markNotificationAsRead = async (request) => {
    try {
        const { notificationId } = request.data;
        const userId = request.auth?.uid;

        if (!userId) {
            throw new Error('User not authenticated');
        }

        if (!notificationId) {
            throw new Error('Notification ID is required');
        }

        const notificationRef = db.collection('Notifications').doc(notificationId);
        const notificationDoc = await notificationRef.get();

        if (!notificationDoc.exists) {
            throw new Error('Notification not found');
        }

        const notificationData = notificationDoc.data();
        if (notificationData.userId !== userId) {
            throw new Error('Access denied');
        }

        await notificationRef.update({
            isRead: true,
            readAt: admin.firestore.FieldValue.serverTimestamp()
        });

        return { success: true, message: 'Notification marked as read' };

    } catch (error) {
        logger.error('Error marking notification as read:', error);
        throw new Error(`Failed to mark notification as read: ${error.message}`);
    }
};

/**
 * 사용자 팔로우 (알림 포함)
 * @param {Object} request - Firebase Functions 요청 객체
 * @param {string} request.data.followedUserId - 팔로우 당할 사용자 ID
 * @param {string} request.auth.uid - 팔로우 하는 사용자 ID
 * @returns {Object} 팔로우 결과
 */
exports.followUserWithNotification = async (request) => {
    try {
        const { followedUserId } = request.data;
        const followerUserId = request.auth?.uid;

        if (!followerUserId) {
            throw new Error('User not authenticated');
        }

        if (!followedUserId) {
            throw new Error('Followed user ID is required');
        }

        if (followerUserId === followedUserId) {
            throw new Error('Cannot follow yourself');
        }

        // 이미 팔로우하고 있는지 확인
        const followingRef = db.collection('Users').doc(followerUserId).collection('Following').doc(followedUserId);
        const followingDoc = await followingRef.get();

        if (followingDoc.exists) {
            return { success: true, message: 'Already following this user' };
        }

        // 팔로우 관계 생성
        const batch = db.batch();
        
        // 팔로워의 Following 컬렉션에 추가
        batch.set(followingRef, {
            followedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        
        // 팔로우 당한 사용자의 Followers 컬렉션에 추가
        const followerRef = db.collection('Users').doc(followedUserId).collection('Followers').doc(followerUserId);
        batch.set(followerRef, {
            followedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        
        await batch.commit();

        // 팔로우 알림 생성
        await notifyUserAboutNewFollower(followedUserId, followerUserId);

        logger.info(`User ${followerUserId} followed user ${followedUserId} and notification sent`);
        return { success: true, message: 'Successfully followed user and notification sent' };

    } catch (error) {
        logger.error('Error following user with notification:', error);
        throw new Error(`Failed to follow user: ${error.message}`);
    }
};

/**
 * 그룹 멤버들에게 새로운 목표 생성 알림 발송
 * @param {string} groupId - 그룹 ID
 * @param {string} goalTitle - 목표 제목
 * @param {string} createdByUserId - 목표 생성자 사용자 ID
 */
async function notifyGroupMembersAboutNewGoal(groupId, goalTitle, createdByUserId) {
    try {
        logger.info(`[notifyGroupMembersAboutNewGoal] Starting to send notifications for goal: ${goalTitle} in group: ${groupId}`);

        // 그룹 정보 조회
        const groupDoc = await db.collection('Groups').doc(groupId).get();
        if (!groupDoc.exists) {
            throw new Error('Group not found');
        }
        const groupData = groupDoc.data();
        const groupName = groupData.name || 'Unknown Group';

        // 목표 생성자 정보 조회
        let creatorName = 'Unknown';
        try {
            const creatorDoc = await db.collection('Users').doc(createdByUserId).get();
            if (creatorDoc.exists) {
                creatorName = creatorDoc.data().name || 'Unknown';
            }
        } catch (error) {
            logger.warn('Failed to get creator name:', error);
        }

        // 그룹 멤버들 조회 (생성자 제외)
        const membersSnapshot = await db.collection('Groups').doc(groupId).collection('members')
            .where('userId', '!=', createdByUserId)
            .get();

        logger.info(`[notifyGroupMembersAboutNewGoal] Found ${membersSnapshot.docs.length} members to notify`);

        // 각 멤버에게 알림 생성
        const promises = membersSnapshot.docs.map(async (memberDoc) => {
            const memberData = memberDoc.data();
            const memberId = memberData.userId;

            try {
                await createNotification(
                    memberId,
                    'group_goal_created',
                    '新しいグループ目標',
                    `${groupName}グループで${creatorName}さんが新しい目標「${goalTitle}」を作成しました`,
                    {
                        groupId: groupId,
                        groupName: groupName,
                        goalTitle: goalTitle,
                        createdBy: createdByUserId,
                        createdByName: creatorName
                    }
                );
                logger.info(`[notifyGroupMembersAboutNewGoal] Notification sent to member: ${memberId}`);
            } catch (error) {
                logger.error(`[notifyGroupMembersAboutNewGoal] Failed to send notification to member ${memberId}:`, error);
            }
        });

        await Promise.all(promises);
        logger.info(`[notifyGroupMembersAboutNewGoal] Successfully sent notifications for goal: ${goalTitle}`);

    } catch (error) {
        logger.error('[notifyGroupMembersAboutNewGoal] Error sending group goal notifications:', error);
        throw error;
    }
}

/**
 * 그룹 멤버들에게 새로운 목표 생성 알림 발송 (독립 실행 함수)
 * @param {Object} request - Firebase Functions 요청 객체
 * @param {string} request.data.groupId - 그룹 ID
 * @param {string} request.data.goalTitle - 목표 제목
 * @param {string} request.data.createdByUserId - 목표 생성자 사용자 ID
 * @param {string} request.auth.uid - 인증된 사용자 ID
 * @returns {Object} 알림 발송 결과
 */
exports.sendGroupGoalNotifications = async (request) => {
    try {
        const { groupId, goalTitle, createdByUserId } = request.data;
        const userId = request.auth?.uid;

        if (!userId) {
            throw new Error('User not authenticated');
        }

        if (!groupId || !goalTitle || !createdByUserId) {
            throw new Error('Group ID, goal title, and creator user ID are required');
        }

        // 권한 확인: 요청자가 목표 생성자와 같거나 그룹 멤버인지 확인
        if (userId !== createdByUserId) {
            const memberSnapshot = await db.collection('Groups').doc(groupId).collection('members')
                .where('userId', '==', userId)
                .get();

            if (memberSnapshot.empty) {
                throw new Error('Access denied. Not a group member.');
            }
        }

        logger.info(`[sendGroupGoalNotifications] Sending notifications for goal: ${goalTitle} in group: ${groupId}`);

        // 그룹 멤버들에게 알림 발송
        await notifyGroupMembersAboutNewGoal(groupId, goalTitle, createdByUserId);

        logger.info(`[sendGroupGoalNotifications] Notifications sent successfully for goal: ${goalTitle}`);
        return { success: true, message: 'Notifications sent successfully' };

    } catch (error) {
        logger.error('[sendGroupGoalNotifications] Error sending notifications:', error);
        throw new Error(`Failed to send notifications: ${error.message}`);
    }
};

// Export helper functions for use in other handlers
module.exports = {
    createNotification,
    notifyGroupMembersAboutNewGoal,
    notifyUserAboutNewFollower,
    getUserNotifications: exports.getUserNotifications,
    markNotificationAsRead: exports.markNotificationAsRead,
    followUserWithNotification: exports.followUserWithNotification,
    sendGroupGoalNotifications: exports.sendGroupGoalNotifications
}; 