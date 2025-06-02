/**
 * 運動分析ハンドラー
 * 
 * このモジュールはユーザーの運動データを分析し、分析結果をFirestoreに保存します。
 * - 身体部位別運動分布
 * - 運動アドヒアランス（遵守率）
 * - お気に入り運動
 * - フォロー中ユーザーとの比較
 * - 1回最大重量（One Rep Max）
 */

const { logger } = require('firebase-functions');
const admin = require('firebase-admin');

// Firebase Admin SDKはindex.jsで初期化済み
const db = admin.firestore();

// 定数定義
const CONSTANTS = {
  TIME: {
    // TODO: 90前から分析してるけど今後帰るかもBMによって
    WORKOUT_LOOKBACK_DAYS: 90, // 分析対象期間（過去90日）
    WEEKLY_DAYS: 7,
    MONTHLY_DAYS: 30
  },
  FAVORITE_EXERCISES: {
    MAX_COUNT: 5 // お気に入り運動の最大表示数
  },
};

// 전역 캐시 변수
let exerciseCache = null;

// 운동 데이터 캐싱 함수
async function loadExerciseData() {
  if (exerciseCache) return exerciseCache;
  
  try {
    const snapshot = await db.collection('Exercises').get();
    const exercises = {};
    
    logger.info(`Found ${snapshot.size} exercises in database`);
    
    snapshot.forEach(doc => {
      const data = doc.data();
      if (data.key && data.part) {
        exercises[data.key] = {
          name: data.name || '',
          part: data.part,
          detailedPart: data.detailedPart || data.part
        };
        logger.info(`Loaded exercise: ${data.key} -> ${data.part}`);
      }
    });
    
    exerciseCache = exercises;
    logger.info(`Exercise cache loaded with ${Object.keys(exercises).length} items`);
    return exercises;
  } catch (error) {
    logger.error(`Error loading exercise data: ${error.message}`);
    return {};
  }
}

// 운동 이름에서 부위 조회 함수
async function getBodyPartFromExercise(exerciseName) {
  if (!exerciseName) return 'other';
  
  // 캐시된 운동 데이터 가져오기
  const exercises = await loadExerciseData();
  
  if (Object.keys(exercises).length === 0) {
    logger.warn(`Exercise database is empty, returning 'other' for ${exerciseName}`);
    return 'other';
  }
  
  // 일본어 운동 이름을 영어로 매핑하는 사전
  const japaneseToEnglish = {
    'ベンチプレス': 'bench press',
    'スクワット': 'squat',
    'デッドリフト': 'deadlift',
    'ダンベルショルダープレス': 'dumbbell shoulder press',
    'チンニング': 'chin-up',
    'プルアップ': 'pull-up',
    'レッグプレス': 'leg press',
    'ディップス': 'dips',
    'プッシュアップ': 'push-up',
    'ラットプルダウン': 'lat pulldown',
    'ケーブルロウ': 'seated cable row'
  };
  
  // 일본어 이름을 영어로 변환 시도
  let englishName = japaneseToEnglish[exerciseName] || exerciseName;
  // 대소문자 정규화 - 항상 소문자로 변환
  englishName = englishName.toLowerCase();
  
  logger.info(`Looking up exercise: ${exerciseName} -> (English: ${englishName})`);
  
  // 다양한 형태의 정규화 시도
  const normalizedName1 = englishName.replace(/\s+/g, '-');
  const normalizedName2 = englishName.replace(/\s+/g, '');
  const normalizedName3 = englishName;
  
  // 정확한 키 매칭 시도
  if (exercises[normalizedName1]) {
    logger.info(`Found exact match for ${normalizedName1}: ${exercises[normalizedName1].part}`);
    return exercises[normalizedName1].part;
  }
  
  // 다른 형태로도 시도
  if (exercises[normalizedName2]) {
    logger.info(`Found match for ${normalizedName2}: ${exercises[normalizedName2].part}`);
    return exercises[normalizedName2].part;
  }
  
  // 부분 일치 시도
  for (const [key, data] of Object.entries(exercises)) {
    // 키도 소문자로 변환해서 비교
    const lowerKey = key.toLowerCase();
    if (normalizedName3.includes(lowerKey) || lowerKey.includes(normalizedName3)) {
      logger.info(`Found partial match: ${normalizedName3} ~ ${key}: ${data.part}`);
      return data.part;
    }
  }
  
  // 직접 매핑 시도 (데이터베이스에 없는 운동을 위한 백업)
  // TODO : db에 없는 운동을 매핑하는
  const directMapping = {
    'bench press': 'chest',
    'squat': 'lower body',
    'deadlift': 'lower body',
    'shoulder press': 'shoulder',
    'bicep curl': 'arm',
    'tricep extension': 'arm',
    'push up': 'chest',
    'pull up': 'back',
    'dips': 'chest',
    'sit up': 'core',
    'plank': 'core',
    'leg press': 'lower body',
    'calf raise': 'lower body',
    'lateral raise': 'shoulder',
    'front raise': 'shoulder',
    'face pull': 'back',
    'barbell row': 'back',
    'lat pulldown': 'back'
  };
  
  // 직접 매핑에서 찾기
  for (const [key, part] of Object.entries(directMapping)) {
    if (englishName.includes(key)) {
      logger.info(`Found in direct mapping: ${englishName} ~ ${key}: ${part}`);
      return part;
    }
  }
  
  logger.warn(`No match found for ${exerciseName}, returning 'other'`);
  return 'other'; // 해당 없는 경우
}

/**
 * 指定されたユーザーの運動分析データを生成・更新する
 * @param {string} userId - 対象ユーザーID
 * @returns {Promise<Object>} 分析結果
 */
async function updateUserAnalytics(userId) {
  try {
    logger.info(`Updating analytics for user: ${userId}`);
    
    // 基本データの取得
    const analysisStartDate = getAnalysisStartDate();
    const workoutResults = await getUserWorkoutResults(userId, analysisStartDate);
    
    if (!workoutResults || workoutResults.length === 0) {
      logger.info(`No workout results found for user ${userId} in analysis period`);
      return { success: false, message: "No workout data available for analysis" };
    }
    
    logger.info(`Found ${workoutResults.length} workout results for analysis`);
    
    // 各分析データの生成
    const distribution = await calculateExerciseDistribution(workoutResults);
    const adherence = await calculateAdherence(userId, workoutResults, analysisStartDate);
    const favoriteExercises = findFavoriteExercises(workoutResults);
    const followingComparison = await calculateFollowingComparison(userId);
    const oneRepMax = calculateOneRepMax(workoutResults);
    
    // 分析データの保存
    const analyticsData = {
      distribution,
      adherence,
      favoriteExercises,
      followingComparison,
      oneRepMax,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };
    
    await saveAnalyticsData(userId, analyticsData);
    
    logger.info(`Successfully updated analytics for user ${userId}`);
    return { success: true, data: analyticsData };
  } catch (error) {
    logger.error(`Error updating analytics for user ${userId}: ${error.message}`);
    return { success: false, error: error.message };
  }
}

/**
 * 分析開始日を取得（現在日から過去X日）
 * @returns {Date} 分析開始日
 */
function getAnalysisStartDate() {
  const now = new Date();
  const startDate = new Date();
  startDate.setDate(now.getDate() - CONSTANTS.TIME.WORKOUT_LOOKBACK_DAYS);
  return startDate;
}

/**
 * ユーザーの運動結果を取得
 * @param {string} userId - ユーザーID
 * @param {Date} startDate - 分析開始日
 * @returns {Promise<Array>} 運動結果配列
 */
async function getUserWorkoutResults(userId, startDate) {
  try {
    logger.info(`Getting workout results for user ${userId} since ${startDate}`);
    
    // 結果を保存する配列
    const results = [];
    
    // Firestoreでユーザーのルートコレクションパス
    const userResultRef = db.collection('Result').doc(userId);
    
    // 月別サブコレクションリストの照会
    const monthCollections = await userResultRef.listCollections();
    logger.info(`Found ${monthCollections.length} month collections for user ${userId}`);
    
    // 各月別コレクションから該当期間の結果を取得
    const queryPromises = monthCollections.map(async (monthCollection) => {
      // 特定の日付以降の結果のみ照会
      const querySnapshot = await monthCollection
        .where('createdAt', '>=', startDate)
        .get();
      
      logger.info(`Found ${querySnapshot.size} results in ${monthCollection.id} for user ${userId}`);
      
      // 結果の追加
      querySnapshot.forEach(doc => {
        const data = doc.data();
        // userIdフィールドがない場合、追加（以前のクエリではこのフィールドでフィルタリングしたため）
        if (!data.userId) {
          data.userId = userId;
        }
        results.push({ id: doc.id, ...data });
      });
    });
    
    // すべてのクエリの完了を待機
    await Promise.all(queryPromises);
    
    logger.info(`Total results found for user ${userId}: ${results.length}`);
    
    return results;
  } catch (error) {
    logger.error(`Error getting workout results: ${error.message}`);
    throw error;
  }
}

/**
 * 身体部位別の運動分布を計算
 * @param {Array} workoutResults - 運動結果配列
 * @returns {Promise<Object>} 身体部位別割合
 */
async function calculateExerciseDistribution(workoutResults) {
  try {
    // 部位別カウント初期化
    const partCount = {};
    let totalCount = 0;
    
    // 各運動結果から部位情報を収集
    for (const workout of workoutResults) {
      if (workout.exercises && Array.isArray(workout.exercises)) {
        for (const exercise of workout.exercises) {
          // 運動名から部位を取得（運動部位がデータに直接ない場合）
          const part = exercise.bodyPart || await getBodyPartFromExercise(exercise.exerciseName);
          
          if (part) {
            partCount[part] = (partCount[part] || 0) + 1;
            totalCount++;
          }
        }
      }
    }
    
    // パーセンテージに変換
    const distribution = {};
    for (const [part, count] of Object.entries(partCount)) {
      distribution[part] = Math.round((count / totalCount) * 100);
    }
    
    return distribution;
  } catch (error) {
    logger.error(`Error calculating exercise distribution: ${error.message}`);
    return {};
  }
}

/**
 * 運動遵守率を計算
 * @param {string} userId - ユーザーID
 * @param {Array} workoutResults - 運動結果配列
 * @param {Date} startDate - 分析開始日
 * @returns {Promise<Object>} 週間・月間遵守率
 * 
 * 현재 코드는 "예정된 날짜에 워크아웃을 했는지"를 기준으로 준수율을 계산합니다. 따라서 5월 12일에 워크아웃을 했더라도, 그 날은 예정된 날짜가 아니기 때문에 "Completed planned days"는 0이 됩니다.
 */
async function calculateAdherence(userId, workoutResults, startDate) {
  try {
    const now = new Date();
    
    // 현재 날짜가 속한 주의 시작일(일요일)과 종료일(토요일) 계산
    const weekStart = new Date(now);
    const currentDayOfWeek = now.getDay(); // 0: 일요일, 1: 월요일, ..., 6: 토요일
    // 현재 요일에 따라 이번 주 일요일로 설정
    weekStart.setDate(now.getDate() - currentDayOfWeek);
    weekStart.setHours(0, 0, 0, 0); // 당일 00:00:00으로 설정
    
    // 이번 주 토요일 설정
    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekStart.getDate() + 6);
    weekEnd.setHours(23, 59, 59, 999); // 당일 23:59:59.999로 설정
    
    // 月の開始日を計算
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1); // 当月の1日
    monthStart.setHours(0, 0, 0, 0);
    
    // 当月の最終日を計算
    const monthEnd = new Date(monthStart);
    monthEnd.setMonth(monthEnd.getMonth() + 1);
    monthEnd.setDate(0);
    monthEnd.setHours(23, 59, 59, 999);
    const daysInMonth = monthEnd.getDate(); // 当月の日数
    
    console.log(`Week boundaries: ${weekStart.toISOString()} - ${weekEnd.toISOString()}`);
    console.log(`Month boundaries: ${monthStart.toISOString()} - ${monthEnd.toISOString()}`);
    
    // 実際の運動日を記録（重複排除）
    const workoutDates = new Set();
    const weeklyWorkoutDates = new Set();
    const monthlyWorkoutDates = new Set();
    
    console.log(`Total workout results found: ${workoutResults.length}`);
    
    // 각 워크아웃 결과를 날짜별로 정렬하여 로깅
    workoutResults.sort((a, b) => {
      const dateA = a.createdAt && (a.createdAt.toDate ? a.createdAt.toDate() : new Date(a.createdAt));
      const dateB = b.createdAt && (b.createdAt.toDate ? b.createdAt.toDate() : new Date(b.createdAt));
      return dateA - dateB;
    });
    
    // 주간 범위 기간 동안의 모든 날짜를 문자열 형식으로 생성 (디버깅용)
    const allWeekDays = new Set();
    let tempDay = new Date(weekStart);
    while (tempDay <= weekEnd) {
      allWeekDays.add(tempDay.toISOString().split('T')[0]);
      tempDay.setDate(tempDay.getDate() + 1);
    }
    console.log(`All days this week: ${Array.from(allWeekDays).join(', ')}`);
    
    workoutResults.forEach(workout => {
      if (workout.createdAt) {
        const workoutDate = workout.createdAt.toDate ? 
          workout.createdAt.toDate() : new Date(workout.createdAt);
        
        // 日付部分のみの文字列に変換して格納（時間情報を除去）
        const dateStr = workoutDate.toISOString().split('T')[0];
        
        console.log(`Found workout on ${dateStr}, id: ${workout.id || 'unknown'}`);
        
        workoutDates.add(dateStr);
        
        // 이번 주 데이터만 필터링 (일요일부터 토요일까지)
        if (workoutDate >= weekStart && workoutDate <= weekEnd) {
          weeklyWorkoutDates.add(dateStr);
          console.log(`  - Added to weekly workouts (${dateStr})`);
        }
        
        // 이번 달 데이터만 필터링
        if (workoutDate >= monthStart && workoutDate <= monthEnd) {
          monthlyWorkoutDates.add(dateStr);
        }
      } else {
        console.log(`Warning: workout without createdAt, id: ${workout.id || 'unknown'}`);
      }
    });
    
    console.log(`Completed workouts this week (${weeklyWorkoutDates.size}): ${Array.from(weeklyWorkoutDates).join(', ')}`);
    
    try {
      // 当週と当月の予定されたワークアウト日を取得
      const [weeklyPlannedDays, monthlyPlannedDays] = await Promise.all([
        getPlannedWorkoutsForDateRange(userId, weekStart, weekEnd),
        getPlannedWorkoutsForDateRange(userId, monthStart, monthEnd)
      ]);
      
      console.log(`Planned workout days this week (${weeklyPlannedDays.size}): ${Array.from(weeklyPlannedDays).join(', ')}`);
      
      // 계산 과정 상세 로깅
      console.log(`== Adherence Calculation Details ==`);
      console.log(`- Weekly planned days: ${weeklyPlannedDays.size}`);
      console.log(`- Weekly completed days: ${weeklyWorkoutDates.size}`);
      
      // 주별/월별 완료율 계산
      let weeklyAdherence = 0;
      if (weeklyPlannedDays.size > 0) {
        // 예정된 날짜 중 실제로 완료한 날짜 수 계산
        const completedPlannedDays = new Set();
        
        weeklyWorkoutDates.forEach(date => {
          console.log(`Checking completed date: ${date}`);
          if (weeklyPlannedDays.has(date)) {
            completedPlannedDays.add(date);
            console.log(`  - ✓ Matches a planned day`);
          } else {
            console.log(`  - ✗ No matching planned day`);
          }
        });
        
        console.log(`Completed planned days (${completedPlannedDays.size}): ${Array.from(completedPlannedDays).join(', ')}`);
        
        // 각 예정된 날짜별로 완료 여부 확인
        weeklyPlannedDays.forEach(plannedDate => {
          const isCompleted = weeklyWorkoutDates.has(plannedDate);
          console.log(`Planned date: ${plannedDate} - ${isCompleted ? 'Completed ✓' : 'Not completed ✗'}`);
        });
        
        // 100% 이상도 허용 (예정된 워크아웃보다 더 많이 수행한 경우)
        weeklyAdherence = Math.round((completedPlannedDays.size / weeklyPlannedDays.size) * 100);
        
        // 추가로 모든 워크아웃 수를 기준으로 한 완료율도 계산하여 로깅
        const totalCompletionRate = Math.round((weeklyWorkoutDates.size / weeklyPlannedDays.size) * 100);
        console.log(`- Weekly adherence (completedPlanned/planned): ${completedPlannedDays.size}/${weeklyPlannedDays.size} = ${weeklyAdherence}%`);
        console.log(`- Total completion rate (total/planned): ${weeklyWorkoutDates.size}/${weeklyPlannedDays.size} = ${totalCompletionRate}%`);
      } else {
        // 예정된 워크아웃이 없는 경우 완료한 워크아웃이 있으면 100%, 없으면 0%
        weeklyAdherence = weeklyWorkoutDates.size > 0 ? 100 : 0;
        console.log(`- No planned days. Weekly adherence set to ${weeklyAdherence}%`);
      }
      
      // 월별 완료율 계산 (주간과 동일한 로직)
      let monthlyAdherence = 0;
      if (monthlyPlannedDays.size > 0) {
        const completedPlannedDays = new Set();
        monthlyWorkoutDates.forEach(date => {
          if (monthlyPlannedDays.has(date)) {
            completedPlannedDays.add(date);
          }
        });
        
        // 100% 이상도 허용
        monthlyAdherence = Math.round((completedPlannedDays.size / monthlyPlannedDays.size) * 100);
        console.log(`- Monthly adherence: ${completedPlannedDays.size}/${monthlyPlannedDays.size} = ${monthlyAdherence}%`);
      } else {
        monthlyAdherence = monthlyWorkoutDates.size > 0 ? 100 : 0;
        console.log(`- No planned days for month. Monthly adherence set to ${monthlyAdherence}%`);
      }
      
      console.log(`Weekly adherence: ${weeklyAdherence}%, Monthly adherence: ${monthlyAdherence}%`);
      
      return {
        thisWeek: weeklyAdherence,
        thisMonth: monthlyAdherence
      };
    } catch (error) {
      logger.error(`Error calculating adherence: ${error.message}`);
      return { thisWeek: 0, thisMonth: 0 };
    }
  } catch (error) {
    logger.error(`Error calculating adherence: ${error.message}`);
    return { thisWeek: 0, thisMonth: 0 };
  }
}

/**
 * 指定された日付範囲内の予定されたワークアウト日を取得
 * @param {string} userId - ユーザーID
 * @param {Date} startDate - 開始日
 * @param {Date} endDate - 終了日
 * @returns {Promise<Set<string>>} 予定されたワークアウト日のセット (YYYY-MM-DD形式)
 */
async function getPlannedWorkoutsForDateRange(userId, startDate, endDate) {
  try {
    console.log(`Getting planned workouts for user ${userId} between ${startDate.toISOString()} and ${endDate.toISOString()}`);
    
    // ユーザーのルーティンワークアウトを取得
    const workoutsRef = db.collection('Workouts');
    const workoutsSnapshot = await workoutsRef
      .where('userId', '==', userId)
      .where('isRoutine', '==', true)
      .get();
    
    console.log(`Found ${workoutsSnapshot.size} routine workouts`);
    
    if (workoutsSnapshot.empty) {
      logger.info(`No routine workouts found for user ${userId}`);
      return new Set();
    }
    
    // 指定期間内の日にち配列を生成
    const daysInRange = [];
    let currentDay = new Date(startDate);
    
    while (currentDay <= endDate) {
      daysInRange.push({
        date: new Date(currentDay),
        dayOfWeek: getDayOfWeek(currentDay)
      });
      currentDay.setDate(currentDay.getDate() + 1);
    }
    
    // 日付範囲内で予定されたワークアウト日を追跡
    const plannedDays = new Set();
    
    // 루틴 워크아웃 상세 정보 로깅
    workoutsSnapshot.forEach(doc => {
      const workout = doc.data();
      console.log(`Routine workout: ${workout.name || 'unnamed'}, id: ${doc.id}`);
      console.log(`  Scheduled days: ${workout.scheduledDays ? workout.scheduledDays.join(', ') : 'none'}`);
      
      // ルーティンに曜日指定があるか確認
      if (workout.scheduledDays && Array.isArray(workout.scheduledDays) && workout.scheduledDays.length > 0) {
        // 日付範囲内の各日をチェック
        daysInRange.forEach(day => {
          if (workout.scheduledDays.includes(day.dayOfWeek)) {
            // 日付を文字列に変換して格納
            const dateStr = day.date.toISOString().split('T')[0];
            plannedDays.add(dateStr);
            console.log(`  - Added planned day: ${dateStr} (${day.dayOfWeek})`);
          }
        });
      }
    });
    
    return plannedDays;
  } catch (error) {
    logger.error(`Error getting planned workouts for date range: ${error.message}`);
    return new Set();
  }
}

/**
 * 日付から曜日を取得（英語形式）
 * @param {Date} date - 日付
 * @returns {string} 曜日（英語）
 */
function getDayOfWeek(date) {
  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  return days[date.getDay()];
}

/**
 * お気に入り運動（最も頻繁に行った運動）を特定
 * @param {Array} workoutResults - 運動結果配列
 * @returns {Array} お気に入り運動情報
 */
function findFavoriteExercises(workoutResults) {
  try {
    // 運動名ごとの出現回数、平均レップ数、平均重量を追跡
    const exerciseStats = {};
    
    workoutResults.forEach(workout => {
      if (workout.exercises && Array.isArray(workout.exercises)) {
        workout.exercises.forEach(exercise => {
          const name = exercise.exerciseName;
          
          if (!name) return;
          
          if (!exerciseStats[name]) {
            exerciseStats[name] = {
              count: 0,
              totalReps: 0,
              totalWeight: 0,
              setCount: 0
            };
          }
          
          exerciseStats[name].count += 1;
          
          // セット情報がある場合、レップ数と重量を集計
          if (exercise.sets && Array.isArray(exercise.sets)) {
            exercise.sets.forEach(set => {
              if (set.Reps) {
                exerciseStats[name].totalReps += set.Reps;
              }
              if (set.Weight) {
                exerciseStats[name].totalWeight += set.Weight;
              }
              exerciseStats[name].setCount += 1;
            });
          }
        });
      }
    });
    
    // 出現回数でソートして上位のお気に入り運動を選択
    const favoriteExercises = Object.entries(exerciseStats)
      .map(([name, stats]) => ({
        name,
        count: stats.count,
        avgReps: stats.setCount > 0 ? Math.round((stats.totalReps / stats.setCount) * 10) / 10 : 0,
        avgWeight: stats.setCount > 0 ? Math.round((stats.totalWeight / stats.setCount) * 10) / 10 : 0
      }))
      .sort((a, b) => b.count - a.count)
      .slice(0, CONSTANTS.FAVORITE_EXERCISES.MAX_COUNT)
      .map(({ name, avgReps, avgWeight }) => ({ name, avgReps, avgWeight }));
    
    return favoriteExercises;
  } catch (error) {
    logger.error(`Error finding favorite exercises: ${error.message}`);
    return [];
  }
}

/**
 * フォロー中ユーザーとの運動頻度比較
 * @param {string} userId - ユーザーID
 * @returns {Promise<Object>} 比較結果
 */
async function calculateFollowingComparison(userId) {
  try {
    // ユーザーのフォロー中リストを取得
    const userDoc = await db.collection('Users').doc(userId).get();
    
    if (!userDoc.exists) {
      return { user: 0, followingAvg: 0 };
    }
    
    const userData = userDoc.data();
    const following = userData.Following || [];
    
    // 自分の週間運動日数を取得
    const userWeeklyWorkouts = await getWeeklyWorkoutCount(userId);
    
    // フォロー中ユーザーの平均週間運動日数を計算
    let totalFollowingWorkouts = 0;
    let followingWithWorkouts = 0;
    
    for (const followingId of following) {
      const weeklyCount = await getWeeklyWorkoutCount(followingId);
      if (weeklyCount > 0) {
        totalFollowingWorkouts += weeklyCount;
        followingWithWorkouts++;
      }
    }
    
    const followingAvg = followingWithWorkouts > 0 ? 
      Math.round(totalFollowingWorkouts / followingWithWorkouts) : 0;
    
    return {
      user: userWeeklyWorkouts,
      followingAvg
    };
  } catch (error) {
    logger.error(`Error calculating following comparison: ${error.message}`);
    return { user: 0, followingAvg: 0 };
  }
}

/**
 * ユーザーの週間運動日数を取得
 * @param {string} userId - ユーザーID
 * @returns {Promise<number>} 週間運動日数
 */
async function getWeeklyWorkoutCount(userId) {
  try {
    const weekStart = new Date();
    weekStart.setDate(weekStart.getDate() - CONSTANTS.TIME.WEEKLY_DAYS);
    
    // 結果を保存するSet（重複日付を削除）
    const workoutDates = new Set();
    
    // Firestoreでユーザーのルートコレクションパス
    const userResultRef = db.collection('Result').doc(userId);
    
    // 月別サブコレクションリストの照会
    const monthCollections = await userResultRef.listCollections();
    
    // 各月別コレクションから該当期間の結果を取得
    const queryPromises = monthCollections.map(async (monthCollection) => {
      // 特定の日付以降の結果のみ照会
      const querySnapshot = await monthCollection
        .where('createdAt', '>=', weekStart)
        .get();
      
      // 日付のみを抽出してSetに追加
      querySnapshot.forEach(doc => {
        const data = doc.data();
        if (data.createdAt) {
          const workoutDate = data.createdAt.toDate ? 
            data.createdAt.toDate() : new Date(data.createdAt);
          
          workoutDates.add(workoutDate.toISOString().split('T')[0]);
        }
      });
    });
    
    // すべてのクエリの完了を待機
    await Promise.all(queryPromises);
    
    return workoutDates.size;
  } catch (error) {
    logger.error(`Error getting weekly workout count: ${error.message}`);
    return 0;
  }
}

/**
 * 1回最大重量（One Rep Max）の計算
 * @param {Array} workoutResults - 運動結果配列
 * @returns {Object} 運動ごとの1回最大重量
 */
function calculateOneRepMax(workoutResults) {
  try {
    // 運動ごとの最大重量を追跡
    const maxLifts = {};
    
    // 重要な複合運動のリスト
    const coreExercises = ['bench press', 'squat', 'deadlift', 'shoulder press'];
    
    workoutResults.forEach(workout => {
      if (workout.exercises && Array.isArray(workout.exercises)) {
        workout.exercises.forEach(exercise => {
          const name = exercise.exerciseName;
          
          if (!name) return;
          
          // 運動名を正規化（小文字化）
          const normalizedName = name.toLowerCase();
          
          // コア運動と一致するか確認
          const matchedCore = coreExercises.find(core => normalizedName.includes(core));
          const exerciseKey = matchedCore || normalizedName;
          
          // セット情報がある場合、最大重量を記録
          if (exercise.sets && Array.isArray(exercise.sets)) {
            exercise.sets.forEach(set => {
              if (set.Weight && set.Weight > 0) {
                // 단순히 사용자가 들어올린 최대 중량을 사용
                if (!maxLifts[exerciseKey] || set.Weight > maxLifts[exerciseKey]) {
                  maxLifts[exerciseKey] = set.Weight;
                }
              }
            });
          }
        });
      }
    });
    
    // 結果を四捨五入して整形
    const result = {};
    for (const [exercise, maxWeight] of Object.entries(maxLifts)) {
      result[exercise] = Math.round(maxWeight * 10) / 10;
    }
    
    return result;
  } catch (error) {
    logger.error(`Error calculating one rep max: ${error.message}`);
    return {};
  }
}

/**
 * 分析データをFirestoreに保存
 * @param {string} userId - ユーザーID
 * @param {Object} analyticsData - 分析データ
 * @returns {Promise<void>}
 */
async function saveAnalyticsData(userId, analyticsData) {
  try {
    await db.collection('UserAnalytics').doc(userId).set(analyticsData);
  } catch (error) {
    logger.error(`Error saving analytics data: ${error.message}`);
    throw error;
  }
}

/**
 * すべてのアクティブユーザーの分析データを更新
 * @returns {Promise<Object>} 更新結果
 */
async function updateAllUsersAnalytics() {
  try {
    logger.info('Starting analytics update for all users');
    
    // アクティブユーザーを取得（最近90日間に運動記録のあるユーザー）
    const activeUsers = await getActiveUsers();
    
    logger.info(`Found ${activeUsers.length} active users for analytics update`);
    
    // 各ユーザーの分析データを更新
    const updatePromises = activeUsers.map(userId => updateUserAnalytics(userId));
    const results = await Promise.allSettled(updatePromises);
    
    // 成功・失敗数を集計
    const succeeded = results.filter(r => r.status === 'fulfilled').length;
    const failed = results.filter(r => r.status === 'rejected').length;
    
    logger.info(`Analytics update completed: ${succeeded} succeeded, ${failed} failed`);
    
    return { 
      success: true, 
      totalUsers: activeUsers.length,
      succeeded,
      failed
    };
  } catch (error) {
    logger.error(`Error updating all users analytics: ${error.message}`);
    return { success: false, error: error.message };
  }
}

/**
 * アクティブユーザー（最近運動記録のあるユーザー）を取得
 * @returns {Promise<Array<string>>} ユーザーID配列
 */
async function getActiveUsers() {
  try {
    const startDate = getAnalysisStartDate();
    logger.info(`Looking for active users since ${startDate}`);
    
    // 結果を保存するSet（重複ユーザーを削除）
    const activeUserIds = new Set();
    
    // Resultコレクションのすべてのドキュメントを取得（ユーザーID）
    const resultUsersSnapshot = await db.collection('Result').get();
    
    // 各ユーザーIDに対して月別コレクションを検索
    const userPromises = resultUsersSnapshot.docs.map(async (userDoc) => {
      const userId = userDoc.id;
      
      // ユーザーの月別コレクションリストを照会
      const monthCollections = await userDoc.ref.listCollections();
      
      // 各月別コレクションで最近の活動の有無を確認
      for (const monthCollection of monthCollections) {
        const recentActivitySnapshot = await monthCollection
          .where('createdAt', '>=', startDate)
          .limit(1)
          .get();
        
        // 最近の活動がある場合、ユーザーIDを追加
        if (!recentActivitySnapshot.empty) {
          activeUserIds.add(userId);
          logger.info(`User ${userId} is active with recent workouts`);
          break; // このユーザーに対する追加検索を中断
        }
      }
    });
    
    // すべてのユーザー検索の完了を待機
    await Promise.all(userPromises);
    
    const activeUsers = Array.from(activeUserIds);
    logger.info(`Found ${activeUsers.length} active users`);
    
    return activeUsers;
  } catch (error) {
    logger.error(`Error getting active users: ${error.message}`);
    return [];
  }
}

module.exports = {
  updateUserAnalytics,
  updateAllUsersAnalytics
}; 