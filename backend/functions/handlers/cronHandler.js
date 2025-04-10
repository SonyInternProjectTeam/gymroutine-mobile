const { getFirestore } = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

// Function to expire stories after 24 hours
exports.expireStories = async (event) => {
  const db = getFirestore(); // Initialize Firestore inside the function
  try {
    logger.info("Running story expiration check");

    const now = new Date();

    // Query for stories that should be expired
    const storiesSnapshot = await db
      .collection("Stories")
      .where("isExpired", "==", false)
      .where("expireAt", "<=", now)
      .get();

    if (storiesSnapshot.empty) {
      logger.info("No stories to expire");
      return;
    }

    // Update each story to mark as expired
    const batch = db.batch();
    let count = 0;

    storiesSnapshot.forEach((doc) => {
      batch.update(doc.ref, { isExpired: true });
      count++;
    });

    await batch.commit();
    logger.info(`Expired ${count} stories`);
  } catch (error) {
    logger.error("Error expiring stories", error);
  }
}; 