/**
 * API Handler for User Recommendations
 * 
 * このモジュールはユーザー推薦関連のAPIエンドポイントを提供します。
 */

const { logger } = require('firebase-functions');
const admin = require('firebase-admin');
const recommendationHandler = require('./recommendationHandler');

// Firebase v2에서는 상위 레벨(index.js)에서 이미 초기화된 admin 인스턴스를 사용합니다.

// 순환 참조를 방지하기 위한 JSON 유틸리티 함수
function safeStringify(obj) {
  const cache = new Set();
  return JSON.stringify(obj, (key, value) => {
    if (typeof value === 'object' && value !== null) {
      if (cache.has(value)) {
        return '[Circular Reference]';
      }
      cache.add(value);
    }
    return value;
  }, 2);
}

/**
 * ユーザー推薦リストを照会します
 * @param {Object} data - リクエストデータ
 * @param {Object} context - Firebase関数コンテキスト
 * @returns {Promise<Object>} 推薦ユーザーリスト
 */
async function getUserRecommendations(data, context) {
  try {
    // 요청 데이터 로깅 - 안전한 JSON 변환 사용
    logger.info(`getUserRecommendations called with data type: ${typeof data}`);
    logger.info(`getUserRecommendations called with data keys: ${Object.keys(data || {})}`);
    if (data && data.userId) {
      logger.info(`Found userId in data: ${data.userId}`);
    } else {
      logger.info(`No userId found in data object`);
    }
    logger.info(`Auth context: ${context.auth ? "Authenticated" : "Not authenticated"}`);
    
    let userId;
    
    if (data && data.userId) {
      // 요청에 userId가 포함된 경우 이를 사용
      userId = data.userId;
      logger.info(`Using provided userId from request: ${userId}`);
    } else if (data && typeof data === 'object' && 'data' in data && data.data && data.data.userId) {
      // 중첩된 데이터 구조에서 userId를 찾는 경우
      userId = data.data.userId;
      logger.info(`Found userId in nested data structure: ${userId}`);
    } else if (context.auth) {
      // 인증된 사용자의 ID 사용
      userId = context.auth.uid;
      logger.info(`Using authenticated user ID: ${userId}`);
    } else {
      // userId나 인증 정보가 없는 경우 에러
      logger.error('No userId provided and no authentication');
      return { 
        success: false, 
        error: "인증 정보나 userId가 필요합니다. 앱에서 userId를 파라미터로 전달해주세요." 
      };
    }
    
    // 추천 목록 조회
    logger.info(`Fetching recommendations for user: ${userId}`);
    const recommendations = await recommendationHandler.getRecommendationsForUser(userId);
    
    // 복잡한 객체 대신 필수 정보만 로깅
    logger.info(`Retrieved recommendations for user: ${userId}. Found: ${recommendations && recommendations.recommendedUsers ? recommendations.recommendedUsers.length : 0} users`);
    
    return { 
      success: true, 
      recommendations: recommendations.recommendedUsers || [] 
    };
  } catch (error) {
    // Fix: Only log the error message and stack, not the entire error object
    logger.error(`Error getting user recommendations: ${error.message}`);
    logger.error(`Stack trace: ${error.stack || 'No stack trace'}`);
    return { 
      success: false, 
      error: error.message 
    };
  }
}

/**
 * 特定ユーザーの推薦リストを強制的に更新します（管理者用または開発用）
 * @param {Object} data - リクエストデータ
 * @param {Object} context - Firebase関数コンテキスト
 * @returns {Promise<Object>} 更新結果
 */
async function forceUpdateRecommendations(data, context) {
  try {
    // 요청 데이터 로깅 - 안전한 JSON 변환 사용
    logger.info(`forceUpdateRecommendations called with data type: ${typeof data}`);
    logger.info(`forceUpdateRecommendations called with data keys: ${Object.keys(data || {})}`);
    if (data && data.userId) {
      logger.info(`Found userId in data: ${data.userId}`);
    } else {
      logger.info(`No userId found in data object`);
    }
    logger.info(`Auth context: ${context.auth ? "Authenticated" : "Not authenticated"}`);
    
    let userId;
    
    if (data && data.userId) {
      // 요청에 userId가 포함된 경우 이를 사용
      userId = data.userId;
      logger.info(`Using provided userId from request: ${userId}`);
    } else if (data && typeof data === 'object' && 'data' in data && data.data && data.data.userId) {
      // 중첩된 데이터 구조에서 userId를 찾는 경우
      userId = data.data.userId;
      logger.info(`Found userId in nested data structure: ${userId}`);
    } else if (context.auth) {
      // 인증된 사용자의 ID 사용
      userId = context.auth.uid;
      logger.info(`Using authenticated user ID: ${userId}`);
    } else {
      // userId나 인증 정보가 없는 경우 에러
      logger.error('No userId provided and no authentication');
      return { 
        success: false, 
        error: "인증 정보나 userId가 필요합니다. 앱에서 userId를 파라미터로 전달해주세요." 
      };
    }
    
    // 추천 목록 강제 갱신
    logger.info(`Forcing recommendation update for user: ${userId}`);
    await recommendationHandler.updateRecommendationsForUser(userId);
    logger.info(`Successfully updated recommendations for user: ${userId}`);
    
    return { success: true };
  } catch (error) {
    // Fix: Only log the error message and stack, not the entire error object
    logger.error(`Error forcing recommendation update: ${error.message}`);
    logger.error(`Stack trace: ${error.stack || 'No stack trace'}`);
    return { 
      success: false, 
      error: error.message 
    };
  }
}

module.exports = {
  getUserRecommendations,
  forceUpdateRecommendations
}; 