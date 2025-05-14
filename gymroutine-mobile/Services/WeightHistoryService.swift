import Foundation
import FirebaseFirestore
import Combine

@MainActor
final class WeightHistoryService {
    static let shared = WeightHistoryService()
    private let db = Firestore.firestore()
    
    /// Fetches weight history for a specific user
    /// - Parameter userId: The user ID to fetch weight history for
    /// - Returns: Array of WeightEntry objects or error
    func fetchWeightHistory(userId: String) async -> Result<[WeightEntry], Error> {
        do {
            // Get the user document from WeightHistory collection
            let docSnapshot = try await db.collection("WeightHistory")
                .document(userId)
                .getDocument()
            
            guard let data = docSnapshot.data() else {
                return .success([]) // No data yet
            }
            
            var weightEntries: [WeightEntry] = []
            
            // Iterate through all fields, looking for ones that start with "weight_"
            for (key, value) in data {
                if key.hasPrefix("weight_"), let entryData = value as? [String: Any] {
                    if let weight = entryData["weight"] as? Double {
                        // Convert date string to timestamp for compatibility with existing code
                        let dateString = entryData["date"] as? String ?? ""
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
                        let date = dateFormatter.date(from: dateString) ?? Date()
                        let timestamp = Timestamp(date: date)
                        
                        let entry = WeightEntry(weight: weight, date: timestamp)
                        weightEntries.append(entry)
                    }
                }
            }
            
            // Sort by date
            weightEntries.sort { $0.date.dateValue() < $1.date.dateValue() }
            
            return .success(weightEntries)
        } catch {
            print("[WeightHistoryService] Error fetching weight history: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    /// Updates user's weight for the current day
    /// - Parameters:
    ///   - userId: The ID of the user to update
    ///   - newWeight: The new weight value
    /// - Returns: Result indicating success or failure
    func updateWeight(userId: String, newWeight: Double) async -> Result<Void, Error> {
        do {
            // Get today's date string in JST (YYYY-MM-DD)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
            let todayDateString = dateFormatter.string(from: Date())
            
            // Create field name based on date
            let fieldName = "weight_\(todayDateString.replacingOccurrences(of: "-", with: ""))"
            
            // Create or update the entry as a map
            let entryData: [String: Any] = [
                "weight": newWeight,
                "date": todayDateString,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            // Create update data with the field
            let updateData = [fieldName: entryData]
            
            // Save to the WeightHistory collection, user document
            try await db.collection("WeightHistory")
                .document(userId)
                .setData(updateData, merge: true)
            
            // Also update the currentWeight field in the user document
            try await db.collection("Users")
                .document(userId)
                .updateData(["currentWeight": newWeight])
            
            // Re-fetch user data to update local state
            await UserManager.shared.fetchInitialUserData(userId: userId)
            
            return .success(())
        } catch {
            print("[WeightHistoryService] Error updating weight: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    /// Migrates weight history data from User document to WeightHistory collection
    /// - Parameter userId: The user ID to migrate data for
    /// - Returns: Result indicating success or failure
    func migrateWeightHistory(userId: String) async -> Result<Void, Error> {
        do {
            // Fetch current user data
            let userSnapshot = try await db.collection("Users")
                .document(userId)
                .getDocument()
            
            guard let userData = userSnapshot.data(),
                  let weightHistoryData = userData["weightHistory"] as? [[String: Any]] else {
                return .success(()) // No data to migrate
            }
            
            // Create a map to hold all the entries
            var updateData: [String: Any] = [:]
            
            for entry in weightHistoryData {
                if let weight = entry["weight"] as? Double,
                   let timestamp = entry["date"] as? Timestamp {
                    
                    // Format date string
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
                    let dateString = dateFormatter.string(from: timestamp.dateValue())
                    
                    // Create field name based on date
                    let fieldName = "weight_\(dateString.replacingOccurrences(of: "-", with: ""))"
                    
                    // Create entry data
                    let entryData: [String: Any] = [
                        "weight": weight,
                        "date": dateString,
                        "createdAt": FieldValue.serverTimestamp()
                    ]
                    
                    // Add to the update data
                    updateData[fieldName] = entryData
                }
            }
            
            // Update the document
            try await db.collection("WeightHistory")
                .document(userId)
                .setData(updateData, merge: true)
            
            return .success(())
        } catch {
            print("[WeightHistoryService] Error migrating weight history: \(error.localizedDescription)")
            return .failure(error)
        }
    }
} 