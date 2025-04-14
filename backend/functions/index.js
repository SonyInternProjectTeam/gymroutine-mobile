/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.getWorkoutStats = functions.https.onCall(async (data, context) => {
  // 認証チェック
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'この機能を使用するには認証が必要です。'
    );
  }

  const userId = context.auth.uid;
  const db = admin.firestore();
  
  try {
    // ユーザーのワークアウトデータを取得
    const workoutsSnapshot = await db
      .collection('workouts')
      .where('userId', '==', userId)
      .get();

    const stats = {
      totalWorkouts: 0,
      partFrequency: {},
      weightProgress: {}
    };

    // データの集計
    workoutsSnapshot.forEach(doc => {
      const workout = doc.data();
      stats.totalWorkouts++;

      // エクササイズごとの集計
      workout.exercises.forEach((exercise) => {
        // 部位ごとの頻度を集計
        const part = exercise.part;
        stats.partFrequency[part] = (stats.partFrequency[part] || 0) + 1;

        // 重量の推移を記録
        if (!stats.weightProgress[exercise.name]) {
          stats.weightProgress[exercise.name] = [];
        }
        
        // 各セットの最大重量を記録
        const maxWeight = Math.max(...exercise.sets.map((set) => set.weight));
        stats.weightProgress[exercise.name].push(maxWeight);
      });
    });

    return stats;
  } catch (error) {
    console.error('Error fetching workout stats:', error);
    throw new functions.https.HttpsError(
      'internal',
      'データの取得中にエラーが発生しました。'
    );
  }
}); 
