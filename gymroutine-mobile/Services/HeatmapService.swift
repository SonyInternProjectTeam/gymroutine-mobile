import Foundation

/// Service that handles business logic for workout heatmap data
final class HeatmapService {
    private let repository = HeatmapRepository()
    
    /// Fetches and converts current month's heatmap data for a specific user
    /// - Parameter userId: User ID
    /// - Returns: Dictionary mapping dates to workout counts
    func getMonthlyHeatmapData(for userId: String) async -> [Date: Int] {
        let result = await repository.fetchMonthlyHeatmapData(for: userId)
        
        switch result {
        case .success(let heatmapDict):
            return convertToDateMap(heatmapDict)
        case .failure(let error):
            print("ERROR: Failed to get heatmap data: \(error.localizedDescription)")
            return [:]
        }
    }
    
    /// Fetches heatmap data for a specific month (for future extensibility)
    /// - Parameters:
    ///   - userId: User ID
    ///   - year: Year
    ///   - month: Month (1-12)
    /// - Returns: Dictionary mapping dates to workout counts
    func getHeatmapData(for userId: String, year: Int, month: Int) async -> [Date: Int] {
        // Create month string in YYYYMM format
        let monthString = String(format: "%04d%02d", year, month)
        
        let result = await repository.fetchMonthlyHeatmapData(for: userId, month: monthString)
        
        switch result {
        case .success(let heatmapDict):
            return convertToDateMap(heatmapDict)
        case .failure(let error):
            print("ERROR: Failed to get heatmap data for \(monthString): \(error.localizedDescription)")
            return [:]
        }
    }
    
    // MARK: - Private Helpers
    
    /// Converts string-based date keys to Date objects
    /// - Parameter stringMap: Heatmap data in [String: Int] format
    /// - Returns: Heatmap data converted to [Date: Int] format
    private func convertToDateMap(_ stringMap: [String: Int]) -> [Date: Int] {
        var dateMap: [Date: Int] = [:]
        
        // Create formatter for string to Date conversion
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for (dateString, count) in stringMap {
            if let date = dateFormatter.date(from: dateString) {
                // Normalize date by removing time information (00:00:00 base)
                let calendar = Calendar.current
                if let normalizedDate = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: date)) {
                    dateMap[normalizedDate] = count
                }
            }
        }
        
        return dateMap
    }
} 