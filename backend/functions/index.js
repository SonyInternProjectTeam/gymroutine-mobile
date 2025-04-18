/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { onCall } = require("firebase-functions/v2/https");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

// Initialize Firebase Admin at the top level
admin.initializeApp();

// Import handlers
const storyHandler = require("./handlers/storyHandler");
const cronHandler = require("./handlers/cronHandler");
const recommendationScheduler = require("./handlers/recommendationScheduler");
const apiHandler = require("./handlers/apiHandler");
const userHandler = require("./handlers/userHandler");

// Export Firestore trigger functions
exports.createStoryFromWorkoutResult = onDocumentCreated(
  "Result/{userId}/{month}/{resultId}",
  storyHandler.createStoryFromWorkoutResult
);

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
