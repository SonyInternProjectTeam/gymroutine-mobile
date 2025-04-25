/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");

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

// Export heatmap update function
// In v2, event payload includes both 'data' (document data) and params from URL pattern
exports.updateWorkoutHeatmap = onDocumentCreated({
  document: "Result/{userId}/{month}/{resultId}",
  // Optional: Specify region if needed
  region: "us-central1" 
}, heatmapHandler.handleResultCreate);

// Export user stats update function (triggered by the same event as heatmap)
exports.updateUserStatsOnWorkout = onDocumentCreated({
  document: "Result/{userId}/{month}/{resultId}",
  region: "us-central1" 
}, userStatsHandler.handleResultCreateForStats);

// Export Firestore trigger functions
exports.createStoryFromWorkoutResult = onDocumentCreated(
  "Result/{userId}/{month}/{resultId}",
  storyHandler.createStoryFromWorkoutResult
);

// Export user following change function
exports.onUserFollowingChange = onDocumentUpdated(
  "Users/{userId}",
  userHandler.onUserFollowingChange
);

// Export scheduled functions
exports.expireStories = onSchedule("every 24 hours", cronHandler.expireStories);
exports.dailyRecommendationUpdate = onSchedule({
  schedule: "0 3 * * *", // 매일 3:00 UTC (일본 시간 정오 12:00)
  timeZone: "Asia/Tokyo"
}, recommendationScheduler.dailyRecommendationUpdate);

// Export API endpoints
exports.getUserRecommendations = onCall(apiHandler.getUserRecommendations);
exports.forceUpdateRecommendations = onCall(apiHandler.forceUpdateRecommendations);

// TODO: Add other function triggers and handlers as needed
