const admin = require("firebase-admin");

/**
 * Convert date to Japan Standard Time (JST, UTC+9)
 * @param {Date} date UTC date object
 * @returns {Date} Date adjusted to JST
 */
function convertToJST(date) {
  const jstOffset = 9 * 60; // 9 hours in minutes
  const utcDate = new Date(date);
  utcDate.setMinutes(utcDate.getMinutes() + jstOffset);
  return utcDate;
}

/**
 * Calculates the difference in days between two dates (considering only date part)
 * @param {Date} date1 First date
 * @param {Date} date2 Second date
 * @returns {number} Difference in days
 */
function daysDifference(date1, date2) {
  const d1 = new Date(date1.getFullYear(), date1.getMonth(), date1.getDate());
  const d2 = new Date(date2.getFullYear(), date2.getMonth(), date2.getDate());
  return Math.round((d1 - d2) / (1000 * 60 * 60 * 24));
}

/**
 * Handler function called when a Result document is created to update user stats
 * @param {Object} event The event payload
 * @param {Object} context The event context
 */
const handleResultCreateForStats = async (event, context) => {
  const db = admin.firestore();
  
  // Extract userId from the document path
  const documentPath = event.document?.split('/') || [];
  if (documentPath.length < 4) {
    console.error("[Stats] Invalid document path format:", event.document);
    return null;
  }
  const userId = documentPath[1];
  
  if (!userId) {
    console.error("[Stats] Could not determine userId from event");
    return null;
  }
  
  // Extract createdAt timestamp
  let completedAt;
  try {
    if (event.data?._fieldsProto?.createdAt?.timestampValue) {
      const timestamp = event.data._fieldsProto.createdAt.timestampValue;
      completedAt = new admin.firestore.Timestamp(
        parseInt(timestamp.seconds), 
        parseInt(timestamp.nanos)
      );
    } else {
      completedAt = admin.firestore.Timestamp.now();
    }
  } catch (error) {
    console.error("[Stats] Error parsing timestamp:", error);
    completedAt = admin.firestore.Timestamp.now();
  }
  
  // Convert to JST and get date components
  const completedDateUTC = completedAt.toDate();
  const completedDateJST = convertToJST(completedDateUTC);
  const year = completedDateJST.getFullYear();
  const month = (completedDateJST.getMonth() + 1).toString().padStart(2, '0');
  const day = completedDateJST.getDate().toString().padStart(2, '0');
  const dateKey = `${year}-${month}-${day}`;

  console.log(`[Stats] Processing workout for user ${userId} on JST date ${dateKey}`);

  // Reference to user document
  const userRef = db.collection("Users").doc(userId);

  try {
    await db.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);
      
      if (!userDoc.exists) {
        console.log(`[Stats] User document ${userId} does not exist. Skipping stats update.`);
        return; // Exit if user document doesn't exist
      }
      
      const userData = userDoc.data();
      // Read existing values directly from transaction data
      const currentTotalDays = userData.totalWorkoutDays || 0; 
      let consecutiveWorkoutDays = userData.consecutiveWorkoutDays || 0;
      const lastWorkoutDateStr = userData.lastWorkoutDate;

      // --- Log values BEFORE calculation --- 
      console.log(`[Stats Transaction] Before calc: lastWorkoutDateStr=${lastWorkoutDateStr}, current dateKey=${dateKey}, current totalDays=${currentTotalDays}, current consecutiveDays=${consecutiveWorkoutDays}`);
      
      let updates = {};
      let needsUpdate = false;

      // --- Calculate Total & Consecutive Days --- 
      // Check if the workout day is different from the last recorded day
      if (dateKey !== lastWorkoutDateStr) {
          // --- This is a workout on a NEW day --- 
          console.log(`[Stats Transaction] Condition met: dateKey (${dateKey}) !== lastWorkoutDateStr (${lastWorkoutDateStr})`);
          needsUpdate = true;
          updates.lastWorkoutDate = dateKey; // Update last workout date string

          // Use FieldValue.increment for atomic update
          updates.totalWorkoutDays = admin.firestore.FieldValue.increment(1);
          console.log(`[Stats Transaction] New day detected. Incrementing totalDays.`);

          // Calculate Consecutive Workout Days
          if (lastWorkoutDateStr) {
              try {
                  const lastWorkoutDate = new Date(lastWorkoutDateStr + 'T00:00:00+09:00'); // Assume JST
                  const diff = daysDifference(completedDateJST, lastWorkoutDate);
                  console.log(`[Stats Transaction] Days difference: ${diff}.`);
                  
                  if (diff === 1) {
                      // Workout was yesterday, increment consecutive days
                      // Use FieldValue.increment if consecutiveWorkoutDays is guaranteed to be numeric
                      // If not, calculate manually like before
                      consecutiveWorkoutDays += 1;
                      updates.consecutiveWorkoutDays = consecutiveWorkoutDays;
                      console.log(`[Stats Transaction] Consecutive day. Updating consecutiveDays to ${consecutiveWorkoutDays}`);
                  } else { // diff > 1 or error parsing date
                      // Gap between workouts or first workout, reset to 1
                      consecutiveWorkoutDays = 1;
                      updates.consecutiveWorkoutDays = consecutiveWorkoutDays;
                      console.log(`[Stats Transaction] Gap detected or first workout. Resetting consecutiveDays to 1`);
                  }
              } catch (e) {
                  console.error("[Stats Transaction] Error parsing lastWorkoutDate for consecutive check:", e);
                  consecutiveWorkoutDays = 1; // Reset on error
                  updates.consecutiveWorkoutDays = consecutiveWorkoutDays;
                  console.log(`[Stats Transaction] Error parsing date. Resetting consecutiveDays to 1`);
              }
          } else {
              // No previous workout date recorded, start at 1
              consecutiveWorkoutDays = 1;
              updates.consecutiveWorkoutDays = consecutiveWorkoutDays;
              console.log(`[Stats Transaction] First recorded workout. Setting consecutiveDays to 1`);
          }
          
      } else {
          // --- Workout on the SAME day as last recorded --- 
          console.log(`[Stats Transaction] Condition NOT met: dateKey (${dateKey}) === lastWorkoutDateStr (${lastWorkoutDateStr}). Stats unchanged.`);
          // No changes needed for totalWorkoutDays or consecutiveWorkoutDays
      }
      
      // --- Perform Update --- 
      if (needsUpdate) {
          console.log(`[Stats Transaction] Attempting update for user ${userId}:`, JSON.stringify(updates));
          // Ensure update only happens if 'updates' object is not empty
          if (Object.keys(updates).length > 0) {
              transaction.update(userRef, updates);
          } else {
              console.log(`[Stats Transaction] 'updates' object is empty, skipping Firestore update.`);
          }
      } else {
          console.log(`[Stats Transaction] No update needed for user ${userId}.`);
      }
    });
    console.log(`[Stats] Successfully processed stats for user ${userId}, date ${dateKey}`);
    return null;
  } catch (error) {
    // Log the specific error during transaction processing
    console.error(`[Stats] Error processing transaction for user ${userId}:`, error);
    return null;
  }
};

// Export the handler function
module.exports = {
  handleResultCreateForStats,
}; 