/**
 * ユーザーデータ変更ハンドラー
 * 
 * このモジュールはユーザーデータ変更時の関連作業を処理します。
 * - Following変更時に推薦リストを更新
 */

const { logger } = require('firebase-functions');
const admin = require('firebase-admin');
const recommendationHandler = require('./recommendationHandler');

// Firebase v2에서는 상위 레벨(index.js)에서 이미 초기화된 admin 인스턴스를 사용합니다.

/**
 * ユーザーのFollowingリスト変更時に推薦リストを更新します
 * @param {Object} change - 変更データ（before/after）
 * @param {Object} context - Firebase関数コンテキスト
 */
async function onUserFollowingChange(change, context) {
  try {
    const userId = context.params.userId;
    const beforeData = change.before.data() || {};
    const afterData = change.after.data() || {};
    
    const beforeFollowing = beforeData.Following || [];
    const afterFollowing = afterData.Following || [];
    
    // Followingリストが変更されたかを確認
    if (JSON.stringify(beforeFollowing) !== JSON.stringify(afterFollowing)) {
      logger.info(`User ${userId} Following changed. Updating recommendations`);
      
      // 推薦リスト更新
      await recommendationHandler.updateRecommendationsForUser(userId);
      
      // 新しくフォローしたユーザーの推薦リストも更新
      const newFollowing = afterFollowing.filter(id => !beforeFollowing.includes(id));
      
      if (newFollowing.length > 0) {
        logger.info(`Updating recommendations for ${newFollowing.length} newly followed users`);
        
        const updatePromises = newFollowing.map(followedUserId => 
          recommendationHandler.updateRecommendationsForUser(followedUserId)
        );
        
        await Promise.all(updatePromises);
      }
      
      logger.info(`Recommendation updates completed for user ${userId} and related users`);
    }
    
    return { success: true };
  } catch (error) {
    logger.error(`Error handling user Following change for ${context.params.userId}:`, error);
    throw error;
  }
}

module.exports = {
  onUserFollowingChange
}; 