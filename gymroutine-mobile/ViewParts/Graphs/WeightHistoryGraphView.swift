import SwiftUI
import Charts
import FirebaseFirestore // For Timestamp

struct WeightHistoryGraphView: View {
    let weightHistory: [WeightEntry]?

    // Find the min and max weight for Y-axis scaling
    private var weightDomain: ClosedRange<Double> {
        guard let history = weightHistory, !history.isEmpty else {
            return 0...100 // Default range if no data
        }
        let weights = history.map { $0.weight }
        let minWeight = weights.min() ?? 0
        let maxWeight = weights.max() ?? 100
        // Add some padding to the domain
        return (minWeight - 5)...(maxWeight + 5)
    }
    
    // Find the min and max date for X-axis scaling (optional, Charts can infer)
    private var dateDomain: ClosedRange<Date> {
         guard let history = weightHistory, !history.isEmpty else {
             // Default range: last 30 days if no data
             let endDate = Date()
             let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
             return startDate...endDate
         }
         let dates = history.map { $0.date.dateValue() } // Convert Timestamps to Dates
         let minDate = dates.min() ?? Date()
         let maxDate = dates.max() ?? Date()
         // Add some padding (e.g., 1 day)
         let paddedStartDate = Calendar.current.date(byAdding: .day, value: -1, to: minDate)!
         let paddedEndDate = Calendar.current.date(byAdding: .day, value: 1, to: maxDate)!
         return paddedStartDate...paddedEndDate
     }


    var body: some View {
        VStack(alignment: .leading) {
            Text("Weight Trend")
                .font(.headline)
                .padding(.bottom, 5)

            if let history = weightHistory, !history.isEmpty {
                Chart {
                    ForEach(history.sorted(by: { $0.date.dateValue() < $1.date.dateValue() }), id: \.self) { entry in
                        LineMark(
                            x: .value("Date", entry.date.dateValue()), // Use converted Date
                            y: .value("Weight", entry.weight)
                        )
                        .foregroundStyle(.blue) // Style the line

                        PointMark(
                             x: .value("Date", entry.date.dateValue()),
                             y: .value("Weight", entry.weight)
                        )
                        .foregroundStyle(.blue)
                        .symbolSize(CGSize(width: 5, height: 5)) // Make points visible
                    }
                }
                .chartYScale(domain: weightDomain) // Set Y-axis scale
                // .chartXScale(domain: dateDomain) // Optional: Set X-axis scale
                .chartXAxis {
                     // Use the no-arg closure with AxisValueLabel for formatting
                     AxisMarks(values: .automatic) {
                         AxisGridLine()
                         AxisTick()
                         AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
                     }
                 }
                .frame(height: 200) // Set a fixed height for the chart
            } else {
                Text("No weight history data available.")
                    .foregroundColor(.secondary)
                    .frame(height: 200, alignment: .center) // Match height for consistency
            }
        }
        .padding() // Add padding around the VStack
    }
}

// Preview Provider
struct WeightHistoryGraphView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample data for preview
        let sampleHistory = [
            WeightEntry(weight: 75.5, date: Timestamp(date: Calendar.current.date(byAdding: .day, value: -20, to: Date())!)),
            WeightEntry(weight: 76.0, date: Timestamp(date: Calendar.current.date(byAdding: .day, value: -15, to: Date())!)),
            WeightEntry(weight: 75.0, date: Timestamp(date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!)),
            WeightEntry(weight: 75.8, date: Timestamp(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!)),
            WeightEntry(weight: 76.2, date: Timestamp(date: Date()))
        ]
        
        let emptyHistory: [WeightEntry]? = []
        let nilHistory: [WeightEntry]? = nil

        VStack {
             WeightHistoryGraphView(weightHistory: sampleHistory)
             WeightHistoryGraphView(weightHistory: emptyHistory)
             WeightHistoryGraphView(weightHistory: nilHistory)
        }
       
    }
} 