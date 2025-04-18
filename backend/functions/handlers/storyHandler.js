const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

// Function triggered when a new workout result is added
exports.createStoryFromWorkoutResult = async (event) => {
  const db = getFirestore(); // Initialize Firestore inside the function
  try {
    // Get the workout result data
    const resultData = event.data.data();
    const resultId = event.params.resultId;
    const userId = event.params.userId;

    if (!resultData) {
      logger.error("No data associated with the event");
      return;
    }

    logger.info(`New workout result created for user ${userId}`, { resultId });

    // Calculate the expiration time (24 hours from now)
    // ToDo: 24 hours is not enough.
    // 時間修正必要
    const now = new Date();
    const expireAtTimestamp = new Date(now.getTime() + 24 * 60 * 60 * 1000);

    // Create a new story document data
    const storyData = {
      userId: userId,
      photo: resultData.photo || null, // Optional photo field
      expireAt: Timestamp.fromDate(expireAtTimestamp), // Use Firestore Timestamp
      isExpired: false,
      visibility: 1, // Default to friends only
      workoutId: resultId,
      createdAt: Timestamp.now(), // Use Firestore Timestamp for creation
    };

    // Add the story document in one operation
    const storyRef = await db.collection("Stories").add(storyData);

    logger.info(`Created story ${storyRef.id} from workout result ${resultId}`);
  } catch (error) {
    logger.error("Error creating story from workout result", error);
  }
}; 