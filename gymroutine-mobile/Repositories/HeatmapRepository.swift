import Foundation
import FirebaseFirestore

/// Repository responsible for accessing Firestore data for workout heatmap
final class HeatmapRepository {
    private let db = Firestore.firestore()
    
    /// Fetches heatmap data for a specific user and month
    /// - Parameters:
    ///   - userId: User ID
    ///   - month: Month in YYYYMM format (defaults to current month)
    /// - Returns: Result containing map of dates to workout counts
    func fetchMonthlyHeatmapData(for userId: String, month: String? = nil) async -> Result<[String: Int], Error> {
        // Use current month if not specified
        let monthString: String
        if let month = month {
            monthString = month
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMM"
            monthString = dateFormatter.string(from: Date())
        }
        
        // Create Firestore document reference
        let docRef = db.collection("WorkoutHeatmap")
            .document(userId)
            .collection(monthString)
            .document("heatmapData")
        
        do {
            let document = try await docRef.getDocument()
            
            // Return empty map if document doesn't exist
            guard document.exists, let data = document.data() else {
                return .success([:])
            }
            
            // Extract date-to-count map from the heatmapData field
            guard let heatmapDict = data["heatmapData"] as? [String: Int] else {
                return .success([:])
            }
            
            return .success(heatmapDict)
        } catch {
            print("DEBUG: Failed to fetch heatmap data: \(error.localizedDescription)")
            return .failure(error)
        }
    }
} 