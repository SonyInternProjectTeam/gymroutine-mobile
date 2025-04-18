/**
 * 推薦システムスケジューラ
 * 
 * このモジュールは定期的なユーザー推薦更新を処理します。
 * - 毎日正午（日本時間）に実行
 * - 過去7日間に活動のあるユーザーのみ更新
 */

const { logger } = require('firebase-functions');
const admin = require('firebase-admin');
const recommendationHandler = require('./recommendationHandler');

// Firebase v2에서는 상위 레벨(index.js)에서 이미 초기화된 admin 인스턴스를 사용합니다.

/**
 * 毎日正午にすべてのアクティブユーザーの推薦リストを更新します
 */
async function dailyRecommendationUpdate() {
  try {
    logger.info('Starting scheduled recommendation update');
    const result = await recommendationHandler.updateAllRecommendations();
    logger.info(`Scheduled recommendation update completed: ${result.updatedCount} users updated`);
    return result;
  } catch (error) {
    logger.error('Error in scheduled recommendation update:', error);
    throw error;
  }
}

module.exports = {
  dailyRecommendationUpdate
}; 