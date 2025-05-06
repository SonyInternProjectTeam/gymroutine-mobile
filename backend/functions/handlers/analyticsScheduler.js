/**
 * 運動分析スケジューラ
 * 
 * このモジュールは定期的なユーザー運動分析データを更新するスケジューラを実装します。
 * - 毎日午前3時（日本時間）に実行
 * - 過去90日間に活動のあるアクティブユーザーの分析データを生成・更新
 */

const { logger } = require('firebase-functions');
const analyticsHandler = require('./analyticsHandler');

/**
 * オブジェクトを安全にシリアライズする関数（循環参照を処理）
 * @param {Object} obj - シリアライズするオブジェクト
 * @returns {string} シリアライズされたJSON文字列
 */
function safeStringify(obj) {
  const cache = new Set();
  return JSON.stringify(obj, (key, value) => {
    if (typeof value === 'object' && value !== null) {
      // 循環参照の検出
      if (cache.has(value)) {
        return '[Circular Reference]';
      }
      cache.add(value);
    }
    return value;
  });
}

/**
 * 毎日のユーザー分析データ更新処理
 * @returns {Promise<Object>} 更新結果
 */
async function dailyAnalyticsUpdate() {
  try {
    logger.info('Starting scheduled analytics update');
    
    // すべてのアクティブユーザーの分析データを更新
    const result = await analyticsHandler.updateAllUsersAnalytics();
    
    logger.info(`Scheduled analytics update completed. Success: ${result.success}, Total users: ${result.totalUsers}, Succeeded: ${result.succeeded}, Failed: ${result.failed}`);
    
    return result;
  } catch (error) {
    logger.error(`Error in scheduled analytics update: ${error.message}`);
    logger.error(`Stack trace: ${error.stack || 'No stack trace'}`);
    return { success: false, error: error.message };
  }
}

/**
 * 特定のユーザーの分析データを単発で更新
 * @param {Object} data - リクエストデータ
 * @param {Object} context - Firebase関数コンテキスト
 * @returns {Promise<Object>} 更新結果
 */
async function manualUserAnalyticsUpdate(data, context) {
  try {
    logger.info(`Manual analytics update requested with data type: ${typeof data}`);
    
    // 循環参照問題を防ぐために安全なシリアライズを使用
    try {
      logger.info(`Full request data: ${safeStringify(data)}`);
    } catch (jsonError) {
      logger.warn(`Failed to stringify request data: ${jsonError.message}`);
    }
    
    let userId;
    
    // ユーザーIDの取得（様々なデータ形式を処理）
    if (data && typeof data === 'object') {
      // データ形式のロギング
      try {
        logger.info(`Data keys: ${Object.keys(data).join(', ')}`);
      } catch (err) {
        logger.warn(`Failed to log data keys: ${err.message}`);
      }
      
      if (data.userId) {
        // 基本形式：{ userId: "xxx" }
        userId = data.userId;
        logger.info(`Found userId directly in request data: ${userId}`);
      } else if (data.data && data.data.userId) {
        // ネストされた形式：{ data: { userId: "xxx" } }
        userId = data.data.userId;
        logger.info(`Found userId in nested data: ${userId}`);
      } else {
        // その他の可能な形式を確認
        for (const key in data) {
          if (typeof data[key] === 'object' && data[key] && data[key].userId) {
            userId = data[key].userId;
            logger.info(`Found userId in nested object at key ${key}: ${userId}`);
            break;
          }
        }
      }
    }
    
    // 認証コンテキストからuserIdを確認
    if (!userId && context && context.auth) {
      userId = context.auth.uid;
      logger.info(`Using authenticated user ID from context: ${userId}`);
    }
    
    // userIdがまだない場合
    if (!userId) {
      logger.error('No userId found in request data or authentication context');
      
      try {
        logger.error(`Request context auth: ${context && context.auth ? 'exists' : 'not exists'}`);
      } catch (err) {
        logger.error(`Failed to log context auth: ${err.message}`);
      }
      
      return { 
        success: false, 
        error: "ユーザーIDが必要です。認証情報またはuserIdパラメータを指定してください。" 
      };
    }
    
    // userIdの有効性検証
    if (typeof userId !== 'string' || userId.trim() === '') {
      logger.error(`Invalid userId: ${userId}`);
      return {
        success: false,
        error: "無効なユーザーID形式です。"
      };
    }
    
    logger.info(`Proceeding with userId: ${userId}`);
    
    // 分析データの更新
    const result = await analyticsHandler.updateUserAnalytics(userId);
    
    logger.info(`Manual analytics update completed for user ${userId}. Success: ${result.success}`);
    
    return result;
  } catch (error) {
    logger.error(`Error in manual analytics update: ${error.message}`);
    
    try {
      logger.error(`Stack trace: ${error.stack || 'No stack trace'}`);
    } catch (err) {
      logger.error('Failed to log error stack trace');
    }
    
    return { success: false, error: error.message };
  }
}

module.exports = {
  dailyAnalyticsUpdate,
  manualUserAnalyticsUpdate
}; 