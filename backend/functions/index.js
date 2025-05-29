/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const functions = require("firebase-functions"); // v1 스타일 import (pubsub 등에 필요할 수 있음)
const { onCall } = require("firebase-functions/v2/https");

// 리전 설정 (예: 도쿄)
const region = "asia-northeast1";

// Initialize Firebase Admin
initializeApp();

// Import handlers
const storyHandler = require("./handlers/storyHandler");
const cronHandler = require("./handlers/cronHandler");
const heatmapHandler = require("./handlers/heatmapHandler");
const userStatsHandler = require("./handlers/userStatsHandler");
const recommendationScheduler = require("./handlers/recommendationScheduler");
const apiHandler = require("./handlers/apiHandler");
const userHandler = require("./handlers/userHandler");
const analyticsScheduler = require('./handlers/analyticsScheduler');
const analyticsHandler = require('./handlers/analyticsHandler');
const groupHandler = require('./handlers/groupHandler');
const notificationHandler = require('./handlers/notificationHandler');

// Export heatmap update function
exports.updateWorkoutHeatmap = onDocumentCreated({
  document: "Result/{userId}/{month}/{resultId}",
  region: region // 리전 설정
}, heatmapHandler.handleResultCreate);

// Export user stats update function (triggered by the same event as heatmap)
exports.updateUserStatsOnWorkout = onDocumentCreated({
  document: "Result/{userId}/{month}/{resultId}",
  region: region // 리전 설정
}, userStatsHandler.handleResultCreateForStats);

// Export Firestore trigger functions
exports.createStoryFromWorkoutResult = onDocumentCreated({
  document: "Result/{userId}/{month}/{resultId}",
  region: region // 리전 설정
}, storyHandler.createStoryFromWorkoutResult);

// Export user following change function
exports.onUserFollowingChange = onDocumentUpdated({
  document: "Users/{userId}",
  region: region // 리전 설정
}, userHandler.onUserFollowingChange);

// Export scheduled functions
exports.expireStories = onSchedule({ 
  schedule: "every 24 hours", 
  region: region // 리전 설정
}, cronHandler.expireStories);

//TODO : change schedule to 0
exports.dailyRecommendationUpdate = onSchedule({
  schedule: "0 0 * * *",
  timeZone: "Asia/Tokyo",
  region: region
}, recommendationScheduler.dailyRecommendationUpdate);

// Export analytics scheduled function
exports.dailyAnalyticsUpdate = onSchedule({
  schedule: "0 3 * * *", // 매일 오전 3시 (일본 시간)
  timeZone: "Asia/Tokyo",
  region: region
}, analyticsScheduler.dailyAnalyticsUpdate);

// Export repeating goals renewal scheduler
exports.renewRepeatingGoals = onSchedule({
  schedule: "0 0 * * *", // 매일 00:00 (일본 시간)
  timeZone: "Asia/Tokyo",
  region: region
}, groupHandler.renewRepeatingGoals);

// Export API endpoints
exports.getUserRecommendations = onCall({ region: region }, apiHandler.getUserRecommendations);
exports.forceUpdateRecommendations = onCall({ region: region }, apiHandler.forceUpdateRecommendations);

// Analytics callable functions
exports.updateUserAnalytics = onCall({ 
  region: region,
  // 함수 호출 전/후 로깅 추가
  beforeCall: (request) => {
    console.log(`updateUserAnalytics called with auth: ${request.auth ? 'authenticated' : 'not authenticated'}`);
    if (request.auth) {
      console.log(`Auth uid: ${request.auth.uid}`);
    }
    
    // 안전한 데이터 로깅을 위해 직접 필요한 정보만 추출
    try {
      const safeData = {
        userId: request.data?.userId || 'not provided',
        hasData: request.data ? true : false,
        dataKeys: request.data ? Object.keys(request.data) : []
      };
      console.log(`Request data (safe): ${JSON.stringify(safeData)}`);
    } catch (error) {
      console.log(`Error logging request data: ${error.message}`);
    }
  },
  afterCall: (request, response) => {
    try {
      const success = response.data?.success || false;
      console.log(`updateUserAnalytics completed with success: ${success}`);
      
      // 에러 정보가 있는 경우만 로깅
      if (!success && response.data?.error) {
        console.log(`Error message: ${response.data.error}`);
      }
    } catch (error) {
      console.log(`Error in afterCall: ${error.message}`);
    }
  }
}, analyticsScheduler.manualUserAnalyticsUpdate);

// Export manual analytics update function
exports.manualUserAnalyticsUpdate = onCall({
  region: region
}, analyticsScheduler.manualUserAnalyticsUpdate);

// Export manual repeating goals renewal function (for testing)
exports.manualRenewRepeatingGoals = onCall({
  region: region
}, groupHandler.renewRepeatingGoals);

// Group management functions (only complex logic that requires backend)
exports.searchUsers = onCall({ region: region }, groupHandler.searchUsers);
exports.inviteUserToGroup = onCall({ region: region }, groupHandler.inviteUserToGroup);
exports.respondToInvitation = onCall({ region: region }, groupHandler.respondToInvitation);
exports.getGroupStatistics = onCall({ region: region }, groupHandler.getGroupStatistics);

// Goal management functions
exports.updateGoalProgress = onCall({ region: region }, groupHandler.updateGoalProgress);
exports.checkGoalCompletion = onCall({ region: region }, groupHandler.checkGoalCompletion);
// Notification functions
exports.getUserNotifications = onCall({ region: region }, notificationHandler.getUserNotifications);
exports.markNotificationAsRead = onCall({ region: region }, notificationHandler.markNotificationAsRead);
exports.followUserWithNotification = onCall({ region: region }, notificationHandler.followUserWithNotification);
exports.sendGroupGoalNotifications = onCall({ region: region }, notificationHandler.sendGroupGoalNotifications);

// TODO: Add other function triggers and handlers as needed
