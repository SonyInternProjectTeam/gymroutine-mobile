const admin = require("firebase-admin");

/**
 * Updates or creates a WorkoutHeatmap document using Firestore transaction
 * @param {FirebaseFirestore.Transaction} transaction Firestore transaction object
 * @param {FirebaseFirestore.DocumentReference} heatmapDocRef Document reference to update
 * @param {string} dateKey Date key to update (YYYY-MM-DD)
 * @param {string} monthId Month ID (YYYYMM)
 */
async function updateOrCreateHeatmap(transaction, heatmapDocRef, dateKey, monthId) {
  const heatmapDoc = await transaction.get(heatmapDocRef);

  if (!heatmapDoc.exists) {
    console.log(`Creating new heatmap document for month ${monthId}`);
    transaction.set(heatmapDocRef, {
      heatmapData: {
        [dateKey]: 1,
      },
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } else {
    console.log(`Updating existing heatmap document for month ${monthId}`);
    transaction.update(heatmapDocRef, {
      [`heatmapData.${dateKey}`]: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

/**
 * Convert date to Japan Standard Time (JST, UTC+9)
 * @param {Date} date UTC date object
 * @returns {Date} Date adjusted to JST
 */
function convertToJST(date) {
  // JST is UTC+9
  const jstOffset = 9 * 60; // 9 hours in minutes
  const utcDate = new Date(date);
  
  // Add 9 hours (540 minutes) to UTC to convert to Japan time
  utcDate.setMinutes(utcDate.getMinutes() + jstOffset);
  
  return utcDate;
}

/**
 * Handler function called when a Result document is created
 * @param {Object} event The event payload
 * @param {Object} context The event context
 */
const handleResultCreate = async (event, context) => {
  const db = admin.firestore();
  
  console.log("Event structure:", JSON.stringify(event, null, 2));
  console.log("Context structure:", JSON.stringify(context, null, 2));
  
  // Extract userId from the document path
  const documentPath = event.document?.split('/') || [];
  // Path format: "Result/{userId}/{month}/{resultId}"
  if (documentPath.length < 4) {
    console.error("Invalid document path format:", event.document);
    return null;
  }
  
  const userId = documentPath[1];
  console.log("Extracted userId from path:", userId);
  
  if (!userId) {
    console.error("Could not determine userId from event");
    return null;
  }
  
  // Extract createdAt timestamp from the event data
  let completedAt;
  
  try {
    if (event.data?._fieldsProto?.createdAt?.timestampValue) {
      const timestamp = event.data._fieldsProto.createdAt.timestampValue;
      // Create Firestore.Timestamp object
      completedAt = new admin.firestore.Timestamp(
        parseInt(timestamp.seconds), 
        parseInt(timestamp.nanos)
      );
      console.log("Extracted timestamp (UTC):", completedAt.toDate());
    } else {
      // Use current time if no timestamp is available
      completedAt = admin.firestore.Timestamp.now();
      console.log("Using current timestamp (UTC):", completedAt.toDate());
    }
  } catch (error) {
    console.error("Error parsing timestamp:", error);
    // Use current time in case of an error
    completedAt = admin.firestore.Timestamp.now();
  }
  
  // Convert UTC time to Japan Standard Time (JST)
  const completedDateUTC = completedAt.toDate();
  const completedDateJST = convertToJST(completedDateUTC);
  
  console.log("UTC Time:", completedDateUTC.toISOString());
  console.log("JST Time:", completedDateJST.toISOString());
  
  // Format date components using JST
  const year = completedDateJST.getFullYear();
  const month = (completedDateJST.getMonth() + 1).toString().padStart(2, '0');
  const day = completedDateJST.getDate().toString().padStart(2, '0');

  const monthId = `${year}${month}`;
  const dateKey = `${year}-${month}-${day}`;

  console.log(`Using JST date: ${dateKey} for month: ${monthId}`);

  // WorkoutHeatmap/{userId}/{YYYYMM}/heatmapData
  const heatmapDocRef = db.collection("WorkoutHeatmap").doc(userId).collection(monthId).doc("heatmapData");

  console.log(`Updating heatmap for user ${userId}, month ${monthId}, date ${dateKey}`);

  try {
    await db.runTransaction(async (transaction) => {
      await updateOrCreateHeatmap(transaction, heatmapDocRef, dateKey, monthId);
    });
    console.log(`Successfully updated heatmap for user ${userId}, date ${dateKey}`);
    return null;
  } catch (error) {
    console.error("Error updating heatmap:", error);
    return null;
  }
};

// Export the handler function
module.exports = {
  handleResultCreate,
}; 