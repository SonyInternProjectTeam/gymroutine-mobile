import SwiftUI
import Charts
import FirebaseFirestore // For Timestamp

struct WeightHistoryGraphView: View {
    @State private var weightHistory: [WeightEntry] = []
    @State private var isLoading = true
    @State private var loadError: Error? = nil
    @State private var selectedEntry: WeightEntry? = nil
    @State private var periodType: PeriodType = .oneMonth
    let userId: String
    
    init(userId: String) {
        self.userId = userId
    }
    
    enum PeriodType: String, CaseIterable, Identifiable {
        case oneWeek = "1週間"
        case oneMonth = "1ヶ月"
        case threeMonths = "3ヶ月"
        case sixMonths = "6ヶ月"
        case oneYear = "1年"
        case all = "全て"
        
        var id: String { self.rawValue }
        
        var days: Int? {
            switch self {
            case .oneWeek: return 7
            case .oneMonth: return 30
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .oneYear: return 365
            case .all: return nil
            }
        }
    }

    // Find the min and max weight for Y-axis scaling
    private var weightDomain: ClosedRange<Double> {
        guard !weightHistory.isEmpty else {
            return 0...100 // Default range if no data
        }
        let weights = weightHistory.map { $0.weight }
        let minWeight = weights.min() ?? 0
        let maxWeight = weights.max() ?? 100
        // Add some padding to the domain
        return (minWeight - 5)...(maxWeight + 5)
    }
    
    // Filter history based on selected period
    private var filteredHistory: [WeightEntry] {
        guard !weightHistory.isEmpty else {
            return []
        }
        
        let sortedHistory = weightHistory.sorted { $0.date.dateValue() < $1.date.dateValue() }
        
        guard let days = periodType.days else {
            // If "all" is selected, return all entries
            return sortedHistory
        }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return sortedHistory.filter { $0.date.dateValue() >= cutoffDate }
    }
    
    // Find the min and max date for X-axis scaling
    private var dateDomain: ClosedRange<Date> {
        guard !filteredHistory.isEmpty else {
            // Default range: last 30 days if no data
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
            return startDate...endDate
        }
        
        let dates = filteredHistory.map { $0.date.dateValue() }
        let minDate = dates.min() ?? Date()
        let maxDate = dates.max() ?? Date()
        
        // Add some padding (e.g., 1 day)
        let paddedStartDate = Calendar.current.date(byAdding: .day, value: -1, to: minDate)!
        let paddedEndDate = Calendar.current.date(byAdding: .day, value: 1, to: maxDate)!
        return paddedStartDate...paddedEndDate
    }
    
    // Calculate weight change summary
    private var weightChangeSummary: String {
        guard !filteredHistory.isEmpty else { return "" }
        
        let sortedHistory = filteredHistory.sorted { $0.date.dateValue() < $1.date.dateValue() }
        guard let firstEntry = sortedHistory.first, let lastEntry = sortedHistory.last else { return "" }
        
        let firstDate = firstEntry.date.dateValue()
        let lastDate = lastEntry.date.dateValue()
        let firstWeight = firstEntry.weight
        let lastWeight = lastEntry.weight
        let difference = lastWeight - firstWeight
        let sign = difference >= 0 ? "+" : ""
        
        let firstFormatter = DateFormatter()
        firstFormatter.dateFormat = "M/d"
        
        let lastFormatter = DateFormatter()
        lastFormatter.dateFormat = "M/d"
        
        return "\(firstFormatter.string(from: firstDate)): \(String(format: "%.1f", firstWeight))kg → \(lastFormatter.string(from: lastDate)): \(String(format: "%.1f", lastWeight))kg (\(sign)\(String(format: "%.1f", difference))kg)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and period picker
            HStack {
                Text("体重変化の推移")
                    .font(.headline)
                
                Spacer()
                
                Picker("期間", selection: $periodType) {
                    ForEach(PeriodType.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Weight change summary
            if !filteredHistory.isEmpty {
                Text(weightChangeSummary)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if isLoading {
                ProgressView()
                    .frame(height: 200, alignment: .center)
            } else if let error = loadError {
                Text("データの読み込みに失敗しました")
                    .foregroundColor(.red)
                    .frame(height: 200, alignment: .center)
            } else if !weightHistory.isEmpty && !filteredHistory.isEmpty {
                // Chart view
                chartView
            } else {
                Text("体重履歴のデータがありません。")
                    .foregroundColor(.secondary)
                    .frame(height: 200, alignment: .center)
            }
        }
        .padding()
        .task {
            await loadWeightHistory()
        }
    }
    
    private func loadWeightHistory() async {
        isLoading = true
        loadError = nil
        
        let result = await WeightHistoryService.shared.fetchWeightHistory(userId: userId)
        
        isLoading = false
        
        switch result {
        case .success(let entries):
            self.weightHistory = entries
        case .failure(let error):
            self.loadError = error
            print("Failed to load weight history: \(error.localizedDescription)")
        }
    }
    
    // Extract chart view for cleaner code
    private var chartView: some View {
        Chart {
            ForEach(filteredHistory, id: \.self) { entry in
                LineMark(
                    x: .value("日付", entry.date.dateValue()),
                    y: .value("体重", entry.weight)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("日付", entry.date.dateValue()),
                    y: .value("体重", entry.weight)
                )
                .foregroundStyle(.blue)
                .symbolSize(entry.self == selectedEntry ? CGSize(width: 10, height: 10) : CGSize(width: 6, height: 6))
            }
            
            if let selectedEntry = selectedEntry {
                RuleMark(
                    x: .value("選択した日付", selectedEntry.date.dateValue())
                )
                .foregroundStyle(Color.gray.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                
                RuleMark(
                    y: .value("選択した体重", selectedEntry.weight)
                )
                .foregroundStyle(Color.gray.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
        }
        .chartXScale(domain: dateDomain)
        .chartYScale(domain: weightDomain)
        .chartXAxis(.visible)
        .chartYAxis(.visible)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    // 터치 제스처를 위한 투명 영역
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let location = value.location
                                    
                                    // Get x-coordinate in chart's coordinate space
                                    guard let xDate = proxy.value(atX: location.x, as: Date.self) else { return }
                                    
                                    // Find the closest data point
                                    let closest = filteredHistory.min { entry1, entry2 in
                                        let date1 = entry1.date.dateValue()
                                        let date2 = entry2.date.dateValue()
                                        return abs(date1.timeIntervalSince(xDate)) < abs(date2.timeIntervalSince(xDate))
                                    }
                                    
                                    selectedEntry = closest
                                }
                        )
                    
                    // 선택된 데이터 포인트 정보 표시
                    if let selectedEntry = selectedEntry, 
                       let selectedDate = selectedEntry.date.dateValue().timeIntervalSince1970 as Double?,
                       let chartMinX = proxy.value(atX: 0, as: Date.self)?.timeIntervalSince1970,
                       let chartMaxX = proxy.value(atX: geometry.size.width, as: Date.self)?.timeIntervalSince1970 {
                        
                        // 선택된 X 위치 계산
                        let dateRange = chartMaxX - chartMinX
                        let datePosition = (selectedDate - chartMinX) / dateRange
                        let xPosition = datePosition * geometry.size.width
                        
                        // 데이터 라벨 표시 위치 계산 (화면 경계 고려)
                        let labelWidth: CGFloat = 150
                        let labelHeight: CGFloat = 60
                        let padding: CGFloat = 10
                        
                        // 왼쪽이나 오른쪽 경계에 가까울 때 위치 조정
                        let adjustedX = min(max(xPosition - labelWidth/2, padding), 
                                            geometry.size.width - labelWidth - padding)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("日付: \(formatDate(selectedEntry.date.dateValue()))")
                                .font(.caption)
                            Text("体重: \(String(format: "%.1f", selectedEntry.weight)) kg")
                                .font(.caption)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(6)
                        .shadow(color: Color.black.opacity(0.1), radius: 2)
                        .position(x: adjustedX + labelWidth/2, y: 30)
                    }
                }
            }
        }
        .frame(height: 200)
    }
    
    // Helper function to format date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// Preview Provider
struct WeightHistoryGraphView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            WeightHistoryGraphView(userId: "previewUserId")
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 2)
                .padding()
                .previewLayout(.sizeThatFits)
        }
        .background(Color.gray.opacity(0.1))
    }
} 
