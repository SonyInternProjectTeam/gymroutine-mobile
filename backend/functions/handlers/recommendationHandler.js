/**
 * ユーザー推薦システムハンドラー
 * 
 * このモジュールはフィットネスSNSアプリのユーザー推薦機能を実装します。
 * - ユーザーの運動パターン、友達ネットワーク、活動性に基づく推薦
 * - ハイブリッドキャッシュ戦略を使用（定期的＆動的更新）
 */

const { logger } = require('firebase-functions');
const admin = require('firebase-admin');

// Firebase v2에서는 상위 레벨(index.js)에서 이미 초기화된 admin 인스턴스를 사용합니다.
const db = admin.firestore();

// 定数定義
const CONSTANTS = {
  SCORE: {
    WORKOUT_SIMILARITY: { MAX: 50, SAME_EXERCISE: 10, SAME_BODY_PART: 5 },
    SOCIAL_NETWORK: { MAX: 30, PER_COMMON_FRIEND: 10 },
    ACTIVITY: { MAX: 20, PER_STORY: 5 },
  },
  TIME: {
    WORKOUT_LOOK_BACK_DAYS: 30,
    ACTIVITY_LOOK_BACK_DAYS: 7,
    INACTIVE_USER_DAYS: 7,
    CACHE_EXPIRY_HOURS: 24,
  },
  RECOMMENDATION: {
    MAX_COUNT: 10,
  },
};

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
 * すべてのユーザーの推薦リストを定期的に更新します（毎日正午）
 */
async function updateAllRecommendations() {
  try {
    logger.info('Starting daily recommendation update');
    
    // アクティブユーザーリストを取得（過去7日間に活動のあるユーザー）
    const activeUsers = await getActiveUsers();
    logger.info(`Found ${activeUsers.length} active users for recommendation update`);
    
    // 各アクティブユーザーに対して推薦リストを更新
    const updatePromises = activeUsers.map(userId => updateRecommendationsForUser(userId));
    await Promise.all(updatePromises);
    
    logger.info('Daily recommendation update completed');
    return { success: true, updatedCount: activeUsers.length };
  } catch (error) {
    logger.error(`Error updating recommendations: ${error.message}`);
    throw error;
  }
}

/**
 * 特定ユーザーの推薦リストを更新します
 * @param {string} userId - 対象ユーザーID
 */
async function updateRecommendationsForUser(userId) {
  try {
    logger.info(`updateRecommendationsForUser started for userId: ${userId}`);
    
    // 1. 候補ユーザーリストを取得
    logger.info(`Fetching candidate users for userId: ${userId}`);
    const candidates = await getCandidateUsers(userId);
    logger.info(`Found ${candidates.length} candidate users for userId: ${userId}`);
    
    // 후보 사용자가 없는 경우 빈 목록 저장
    if (!candidates || candidates.length === 0) {
      logger.info(`No candidate users found for userId: ${userId}. Saving empty recommendations.`);
      await saveRecommendations(userId, []);
      return { success: true, recommendedUsers: [] };
    }
    
    // 2. 各候補のスコアを計算
    logger.info(`Calculating scores for ${candidates.length} candidates`);
    const scoredCandidates = await scoreCandidates(userId, candidates);
    
    // 3. 上位N人を選択
    logger.info(`Selecting top candidates from ${scoredCandidates.length} scored candidates`);
    const topRecommendations = selectTopCandidates(scoredCandidates);
    logger.info(`Selected ${topRecommendations.length} top candidates`);
    
    // 4. Firestoreに推薦リストを保存
    logger.info(`Saving recommendations to Firestore for userId: ${userId}`);
    await saveRecommendations(userId, topRecommendations);
    
    logger.info(`Successfully updated recommendations for user: ${userId}`);
    return { success: true, recommendedUsers: topRecommendations };
  } catch (error) {
    logger.error(`Error updating recommendations for user ${userId}: ${error.message}`);
    throw error;
  }
}

/**
 * ユーザーリクエスト時に推薦リストを照会し、必要に応じて更新します
 * @param {string} userId - 対象ユーザーID
 */
async function getRecommendationsForUser(userId) {
  try {
    logger.info(`getRecommendationsForUser called for userId: ${userId}`);
    
    const recommendationsRef = db.collection('Recommendations').doc(userId);
    logger.info(`Checking existing recommendations for userId: ${userId}`);
    
    const recommendationsDoc = await recommendationsRef.get();
    
    // キャッシュがないか期限切れかを確認
    if (!recommendationsDoc.exists || isCacheExpired(recommendationsDoc.data())) {
      logger.info(`No recommendations found or cache expired for userId: ${userId}`);
      
      // 最近24時間以内にFollowing/Resultに変更があるか確認
      logger.info(`Checking recent changes for userId: ${userId}`);
      const hasRecentChanges = await checkRecentChanges(userId);
      
      if (hasRecentChanges) {
        logger.info(`Recent changes found for userId: ${userId}, calculating new recommendations`);
        // 推薦リストを新しく計算
        await updateRecommendationsForUser(userId);
        const newRecommendations = await recommendationsRef.get();
        logger.info(`New recommendations generated for userId: ${userId}`);
        return newRecommendations.data();
      } else {
        logger.info(`No recent changes for userId: ${userId}, but cache expired. Using existing recommendations.`);
      }
    } else {
      logger.info(`Found valid cached recommendations for userId: ${userId}`);
    }
    
    // 既存のキャッシュされた推薦リストを返却
    return recommendationsDoc.exists ? recommendationsDoc.data() : { recommendedUsers: [] };
  } catch (error) {
    logger.error(`Error getting recommendations for user ${userId}: ${error.message}`);
    throw error;
  }
}

/**
 * 過去7日間に活動のあるユーザーリストを取得します
 * @returns {Promise<string[]>} アクティブユーザーID配列
 */
async function getActiveUsers() {
  try {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - CONSTANTS.TIME.INACTIVE_USER_DAYS);
    
    // Resultコレクションから最近の活動ユーザーを確認
    const activeResultUsers = new Set();
    const resultSnapshot = await db.collectionGroup('Result')
      .where('createdAt', '>=', sevenDaysAgo)
      .get();
    
    resultSnapshot.forEach(doc => {
      const userId = doc.ref.path.split('/')[1]; // Result/{userId}/{month}/{resultId} パスから抽出
      activeResultUsers.add(userId);
    });
    
    // Storiesコレクションから最近の活動ユーザーを確認
    const storiesSnapshot = await db.collection('Stories')
      .where('createdAt', '>=', sevenDaysAgo)
      .get();
    
    const activeUserIds = [];
    storiesSnapshot.forEach(doc => {
      const storyData = doc.data();
      if (storyData.userId) {
        activeResultUsers.add(storyData.userId);
      }
    });
    
    // Setを配列に変換
    return Array.from(activeResultUsers);
  } catch (error) {
    logger.error(`Error getting active users: ${error.message}`);
    throw error;
  }
}

/**
 * 推薦対象候補ユーザーを取得します（現在フォローしていないアクティブユーザー）
 * @param {string} userId - 対象ユーザーID
 * @returns {Promise<string[]>} 候補ユーザーID配列
 */
async function getCandidateUsers(userId) {
  try {
    logger.info(`Getting candidate users for userId: ${userId}`);
    
    // 1. ユーザー情報の取得
    const userDoc = await db.collection('Users').doc(userId).get();
    
    if (!userDoc.exists) {
      logger.warn(`User ${userId} not found`);
      return [];
    }
    
    // 2. Following 리스트 가져오기 (두 가지 방법으로 시도)
    let following = [];
    
    // 방법 1: 사용자 문서의 Following 필드 확인
    const userData = userDoc.data();
    if (userData.Following && Array.isArray(userData.Following)) {
      following = userData.Following;
      logger.info(`Found ${following.length} following users in user document Following field`);
    }
    
    // 방법 2: Following 서브컬렉션 확인 (백업 방법)
    if (following.length === 0) {
      try {
        const followingSnapshot = await db.collection('Users').doc(userId).collection('Following').get();
        if (!followingSnapshot.empty) {
          following = followingSnapshot.docs.map(doc => doc.id);
          logger.info(`Found ${following.length} following users in Following subcollection`);
        }
      } catch (error) {
        logger.warn(`Error getting Following subcollection: ${error.message}`);
      }
    }
    
    // 자신을 팔로잉 목록에 추가 (자기 자신은 추천하지 않음)
    following.push(userId);
    logger.info(`Total following users (including self): ${following.length}`);
    
    // 3. アクティブユーザーリストを取得
    const activeUsersSnapshot = await db.collection('Users').where('Visibility', '!=', 0).get();
    logger.info(`Found ${activeUsersSnapshot.size} total users in database`);
    
    // 4. フォローしていないアクティブユーザーをフィルタリング
    const candidates = [];
    activeUsersSnapshot.forEach(doc => {
      if (!following.includes(doc.id)) {
        candidates.push(doc.id);
      }
    });
    
    logger.info(`Found ${candidates.length} candidate users after filtering out following users`);
    
    // 5. 디버깅을 위해 처음 몇 개의 후보와 팔로잉 유저 로깅
    if (following.length > 0) {
      logger.info(`First few following users: ${following.slice(0, 5).join(', ')}${following.length > 5 ? '...' : ''}`);
    }
    if (candidates.length > 0) {
      logger.info(`First few candidate users: ${candidates.slice(0, 5).join(', ')}${candidates.length > 5 ? '...' : ''}`);
    }
    
    return candidates;
  } catch (error) {
    logger.error(`Error getting candidate users for ${userId}: ${error.message}`);
    throw error;
  }
}

/**
 * 候補ユーザーにスコアを付与します
 * @param {string} userId - 対象ユーザーID
 * @param {string[]} candidates - 候補ユーザーID配列
 * @returns {Promise<Array<{userId: string, score: number}>>} スコアが付与された候補リスト
 */
async function scoreCandidates(userId, candidates) {
  try {
    const scoredCandidates = [];
    
    // ユーザーデータの取得
    const userDoc = await db.collection('Users').doc(userId).get();
    if (!userDoc.exists) return [];
    
    const userData = userDoc.data();
    const userFollowing = userData.Following || [];
    const userFollowers = userData.Followers || [];
    
    // ユーザーの運動記録を取得
    const userWorkouts = await getUserWorkoutData(userId);
    
    // 各候補についてスコア計算
    for (const candidateId of candidates) {
      let totalScore = 0;
      
      // 1. 運動類似性スコア（最大50点）
      const workoutSimilarityScore = await calculateWorkoutSimilarity(userWorkouts, candidateId);
      totalScore += workoutSimilarityScore;
      
      // 2. 友達ネットワークスコア（最大30点）
      const networkScore = await calculateNetworkScore(userFollowing, userFollowers, candidateId);
      totalScore += networkScore;
      
      // 3. 活動性スコア（最大20点）
      const activityScore = await calculateActivityScore(candidateId);
      totalScore += activityScore;
      
      scoredCandidates.push({
        userId: candidateId,
        score: totalScore
      });
    }
    
    return scoredCandidates;
  } catch (error) {
    logger.error(`Error scoring candidates for ${userId}: ${error.message}`);
    throw error;
  }
}

/**
 * 運動類似性スコアを計算します（最大50点）
 * @param {Array<{exerciseType: string, bodyPart: string}>} userWorkouts - ユーザー運動データ
 * @param {string} candidateId - 候補ユーザーID
 * @returns {Promise<number>} 運動類似性スコア
 */
async function calculateWorkoutSimilarity(userWorkouts, candidateId) {
  try {
    // 候補ユーザーの運動記録を取得
    const candidateWorkouts = await getUserWorkoutData(candidateId);
    
    if (!userWorkouts.length || !candidateWorkouts.length) {
      return 0;
    }
    
    let sameExerciseCount = 0;
    let sameBodyPartCount = 0;
    
    // 同じ運動および身体部位をカウント
    userWorkouts.forEach(userWorkout => {
      candidateWorkouts.forEach(candidateWorkout => {
        if (userWorkout.exerciseType === candidateWorkout.exerciseType) {
          sameExerciseCount++;
        } else if (userWorkout.bodyPart === candidateWorkout.bodyPart) {
          sameBodyPartCount++;
        }
      });
    });
    
    // スコア計算（同じ運動10点、同じ部位5点、最大50点）
    const score = Math.min(
      (sameExerciseCount * CONSTANTS.SCORE.WORKOUT_SIMILARITY.SAME_EXERCISE) +
      (sameBodyPartCount * CONSTANTS.SCORE.WORKOUT_SIMILARITY.SAME_BODY_PART),
      CONSTANTS.SCORE.WORKOUT_SIMILARITY.MAX
    );
    
    return score;
  } catch (error) {
    logger.error(`Error calculating workout similarity for candidate ${candidateId}: ${error.message}`);
    return 0;
  }
}

/**
 * ユーザーの最近の運動データを取得します
 * @param {string} userId - ユーザーID
 * @returns {Promise<Array<{exerciseType: string, bodyPart: string}>>} 運動データ配列
 */
async function getUserWorkoutData(userId) {
  try {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - CONSTANTS.TIME.WORKOUT_LOOK_BACK_DAYS);
    
    // Resultコレクショングループからユーザーの最近の運動結果を取得
    const resultSnapshot = await db.collectionGroup('Result')
      .where('userId', '==', userId)
      .where('createdAt', '>=', thirtyDaysAgo)
      .get();
    
    const workouts = [];
    resultSnapshot.forEach(doc => {
      const resultData = doc.data();
      if (resultData.exerciseType && resultData.bodyPart) {
        workouts.push({
          exerciseType: resultData.exerciseType,
          bodyPart: resultData.bodyPart
        });
      }
    });
    
    return workouts;
  } catch (error) {
    logger.error(`Error getting workout data for user ${userId}: ${error.message}`);
    return [];
  }
}

/**
 * 友達ネットワークスコアを計算します（最大30点）
 * @param {string[]} userFollowing - ユーザーがフォローしている人々
 * @param {string[]} userFollowers - ユーザーをフォローしている人々
 * @param {string} candidateId - 候補ユーザーID
 * @returns {Promise<number>} ネットワークスコア
 */
async function calculateNetworkScore(userFollowing, userFollowers, candidateId) {
  try {
    // 候補ユーザー情報の取得
    const candidateDoc = await db.collection('Users').doc(candidateId).get();
    
    if (!candidateDoc.exists) {
      return 0;
    }
    
    const candidateData = candidateDoc.data();
    const candidateFollowing = candidateData.Following || [];
    const candidateFollowers = candidateData.Followers || [];
    
    // 共通のフォロー/フォロワー数を計算
    const commonFollowing = userFollowing.filter(id => candidateFollowing.includes(id));
    const commonFollowers = userFollowers.filter(id => candidateFollowers.includes(id));
    
    // 重複を除去
    const commonConnections = [...new Set([...commonFollowing, ...commonFollowers])];
    
    // スコア計算（共通の接続1人につき10点、最大30点）
    const score = Math.min(
      commonConnections.length * CONSTANTS.SCORE.SOCIAL_NETWORK.PER_COMMON_FRIEND,
      CONSTANTS.SCORE.SOCIAL_NETWORK.MAX
    );
    
    return score;
  } catch (error) {
    logger.error(`Error calculating network score for candidate ${candidateId}: ${error.message}`);
    return 0;
  }
}

/**
 * 活動性スコアを計算します（最大20点）
 * @param {string} candidateId - 候補ユーザーID
 * @returns {Promise<number>} 活動性スコア
 */
async function calculateActivityScore(candidateId) {
  try {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - CONSTANTS.TIME.ACTIVITY_LOOK_BACK_DAYS);
    
    // 最近7日間のストーリー数を計算
    const storiesSnapshot = await db.collection('Stories')
      .where('userId', '==', candidateId)
      .where('createdAt', '>=', sevenDaysAgo)
      .get();
    
    const storyCount = storiesSnapshot.size;
    
    // スコア計算（ストーリー1件につき5点、最大20点）
    const score = Math.min(
      storyCount * CONSTANTS.SCORE.ACTIVITY.PER_STORY,
      CONSTANTS.SCORE.ACTIVITY.MAX
    );
    
    return score;
  } catch (error) {
    logger.error(`Error calculating activity score for candidate ${candidateId}: ${error.message}`);
    return 0;
  }
}

/**
 * 上位候補を選択します
 * @param {Array<{userId: string, score: number}>} scoredCandidates - スコアが付与された候補リスト
 * @returns {Array<{userId: string, score: number}>} 上位N人の候補
 */
function selectTopCandidates(scoredCandidates) {
  // スコアでソート（降順）
  const sortedCandidates = [...scoredCandidates].sort((a, b) => b.score - a.score);
  
  // 上位N人を返却
  return sortedCandidates.slice(0, CONSTANTS.RECOMMENDATION.MAX_COUNT);
}

/**
 * 推薦リストをFirestoreに保存します
 * @param {string} userId - ユーザーID
 * @param {Array<{userId: string, score: number}>} recommendations - 推薦リスト
 */
async function saveRecommendations(userId, recommendations) {
  try {
    await db.collection('Recommendations').doc(userId).set({
      recommendedUsers: recommendations,
      updatedAt: new Date()
    });
  } catch (error) {
    logger.error(`Error saving recommendations for user ${userId}: ${error.message}`);
    throw error;
  }
}

/**
 * キャッシュが期限切れかどうかを確認します
 * @param {Object} recommendationsData - 推薦データ
 * @returns {boolean} キャッシュの期限切れの有無
 */
function isCacheExpired(recommendationsData) {
  if (!recommendationsData || !recommendationsData.updatedAt) {
    return true;
  }
  
  const updatedAt = recommendationsData.updatedAt.toDate();
  const now = new Date();
  const hoursDiff = (now - updatedAt) / (1000 * 60 * 60);
  
  return hoursDiff >= CONSTANTS.TIME.CACHE_EXPIRY_HOURS;
}

/**
 * 最近24時間以内にユーザーのFollowingまたはResultに変更があるか確認します
 * @param {string} userId - ユーザーID
 * @returns {Promise<boolean>} 最近の変更の有無
 */
async function checkRecentChanges(userId) {
  try {
    const oneDayAgo = new Date();
    oneDayAgo.setDate(oneDayAgo.getDate() - 1);
    
    // ユーザー文書の変更を確認（Following変更）
    const userDoc = await db.collection('Users').doc(userId).get();
    
    if (!userDoc.exists) {
      return false;
    }
    
    const userData = userDoc.data();
    
    if (userData.updatedAt && userData.updatedAt.toDate() >= oneDayAgo) {
      return true;
    }
    
    try {
      // 最近のResult追加を確認
      const resultSnapshot = await db.collectionGroup('Result')
        .where('userId', '==', userId)
        .where('createdAt', '>=', oneDayAgo)
        .limit(1)
        .get();
      
      return !resultSnapshot.empty;
    } catch (indexError) {
      // 인덱스 오류 처리 - 인덱스가 없으면 이 쿼리는 실패할 수 있음
      logger.warn(`Index error when checking recent results for user ${userId}: ${indexError.message}`);
      logger.warn(`Visit the following URL to create the required index: ${indexError.message.includes('https://console.firebase.google.com') ? indexError.message.substring(indexError.message.indexOf('https')) : 'Firebase Console'}`);
      
      // 인덱스 오류의 경우, 안전하게 false를 반환하여 기존 캐시를 사용하게 함
      return false;
    }
    
  } catch (error) {
    logger.error(`Error checking recent changes for user ${userId}: ${error.message}`);
    // 오류 발생 시 그대로 오류를 던지지 않고 false를 반환하여 안전하게 처리
    return false;
  }
}

module.exports = {
  updateAllRecommendations,
  updateRecommendationsForUser,
  getRecommendationsForUser
}; 