import SwiftUI

struct HeatmapCalendarView: View {
    let heatmapData: [Date: Int] // Expects data like [Date: WorkoutCount]
    var startDate: Date // Starting date to display
    var numberOfMonths: Int = 6 // Default to show 6 months
    var isCompactMode: Bool = false // Compact mode for profile view
    
    private let daysOfWeek = ["日", "月", "火", "水", "木", "金", "土"]
    // MARK: - 셀 크기 설정 (flexible로 설정하여 화면에 맞게 동적 조정)
    private let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 7)
    private let cellSpacing: CGFloat = 3 // Reduced spacing
    
    // 셀 크기 설정
    private let multiMonthCellSize: CGFloat = 25 // 멀티 월 뷰 셀 크기
    private let compactCellSize: CGFloat = 16 // Compact 모드 셀 크기
    
    // Month formatter
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月" // Short month name (e.g., "Jan")
        return formatter
    }()
    
    // Year formatter
    private let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年"
        return formatter
    }()
    
    init(heatmapData: [Date: Int], startDate: Date? = nil, numberOfMonths: Int = 6, isCompactMode: Bool = false) {
        self.heatmapData = heatmapData
        self.isCompactMode = isCompactMode
        
        // If startDate is not provided, calculate to show the most recent months
        if let startDate = startDate {
            self.startDate = startDate
        } else {
            // Default to showing current month - (numberOfMonths-1)
            let calendar = Calendar.current
            let currentMonth = calendar.startOfDay(for: Date())
            if let calculatedStart = calendar.date(byAdding: .month, value: -(numberOfMonths-1), to: currentMonth) {
                self.startDate = calendar.startOfDay(for: calculatedStart)
            } else {
                self.startDate = calendar.startOfDay(for: Date())
            }
        }
        
        self.numberOfMonths = numberOfMonths
    }
    
    var body: some View {
        if isCompactMode {
            // 프로필 뷰를 위한 컴팩트 모드 - GeometryReader 없이 직접 렌더링
            compactHeatmapView()
        } else {
            // 기존의 GeometryReader 기반 뷰
        GeometryReader { geometry in
            // MARK: - 화면 너비에서 패딩을 고려하여 가용 너비 계산
            let availableWidth = geometry.size.width - 32  // 좌우 패딩 고려
            
            VStack(alignment: .leading, spacing: 12) {
                // Only show title for multi-month view
                if numberOfMonths > 1 {
                    Text("Workout Activity")
                        .font(.headline)
                        .padding(.bottom, 4)
                }
                
                if numberOfMonths == 1 {
                    // Optimized single month view for home screen
                    singleMonthView(for: startDate, availableWidth: availableWidth)
                } else {
                    // Multi-month scrollable view
                    multiMonthView()
                }
                
                // Only show legend for multi-month view or if space allows
                if numberOfMonths > 1 {
                    // Color legend
                    HStack(spacing: 3) {
                        Text("Less")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        ForEach(0...4, id: \.self) { level in
                            Rectangle()
                                .fill(colorForLevel(level))
                                .frame(width: 12, height: 12)
                                .cornerRadius(2)
                        }
                        
                        Text("More")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                    .padding(.leading, 24) // Align with grid
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    // MARK: - 프로필 뷰를 위한 컴팩트 모드
    private func compactHeatmapView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Month header
            HStack {
                let month = monthFormatter.string(from: startDate)
                let year = yearFormatter.string(from: startDate)
                Text("\(year)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            // 컴팩트한 일주일 표시
            HStack(spacing: 4) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Compact month grid for first 2 months
            VStack(spacing: 12) {
                ForEach(0..<min(numberOfMonths, 3), id: \.self) { monthIndex in
                    if let monthDate = Calendar.current.date(byAdding: .month, value: -monthIndex, to: startDate) {
                        compactMonthHeatmapGrid(for: monthDate)
                    }
                }
            }
            
            // Color legend (more compact)
            HStack(spacing: 2) {
                Text("Less")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                
                ForEach(0...4, id: \.self) { level in
                    Rectangle()
                        .fill(colorForLevel(level))
                        .frame(width: 8, height: 8)
                        .cornerRadius(1)
                }
                
                Text("More")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 2)
            .frame(maxWidth: .infinity, alignment: .center) // hAlign(.center) 대신에 직접 frame 사용
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(10)
    }
    
    // 컴팩트 모드용 월 그리드
    private func compactMonthHeatmapGrid(for date: Date) -> some View {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        // Calculate days in month
        let range = calendar.range(of: .day, in: .month, for: date)!
        let numDays = range.count
        
        // Get first day of month and its weekday
        let firstDay = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let firstWeekday = calendar.component(.weekday, from: firstDay) // 1 = Sunday, 7 = Saturday
        
        let emptyCellsCount = firstWeekday - 1
        
        let monthName = monthFormatter.string(from: date)
        
        return VStack(alignment: .leading, spacing: 4) {
            Text(monthName)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: columns, spacing: cellSpacing) {
                // Empty cells for padding before first day
                ForEach(0..<emptyCellsCount, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: compactCellSize, height: compactCellSize)
                }
                
                // Day cells
                ForEach(1...numDays, id: \.self) { day in
                    if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                        let dayCount = heatmapData[calendar.startOfDay(for: date)] ?? 0
                        ZStack {
                            Rectangle()
                                .fill(colorForCount(dayCount))
                                .frame(width: compactCellSize, height: compactCellSize)
                                .cornerRadius(2)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private func singleMonthView(for date: Date, availableWidth: CGFloat) -> some View {
        // MARK: - 싱글 월 뷰 셀 크기 계산 (화면 폭을 기준으로)
        // 7.5 = 7(날짜 수) + 0.5(여유 공간)으로 나누어 약간 작게 설정
        let cellSize = (availableWidth - (6 * cellSpacing)) / 10
        
        return VStack(alignment: .leading, spacing: 8) {
            // Month header
            HStack {
                let month = monthFormatter.string(from: date)
                let year = yearFormatter.string(from: date)
                Text("\(year) \(month)")
                    .font(.headline)
                Spacer()
            }
            
            // Days of Week Header
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar Grid - no scrolling needed for single month
            monthHeatmapGrid(for: date, cellSize: cellSize)
        }
    }
    
    private func multiMonthView() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Month headers row
            HStack(alignment: .bottom, spacing: 0) {
                // Day of week labels (left side)
                VStack(alignment: .trailing, spacing: cellSpacing + 2) {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .frame(width: 16, height: multiMonthCellSize) // 멀티 월 뷰 셀 크기 사용
                    }
                }
                .padding(.trailing, 4)
                
                // Scrollable month headers
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 0) {
                        ForEach(0..<numberOfMonths, id: \.self) { index in
                            if let monthDate = Calendar.current.date(byAdding: .month, value: index, to: startDate) {
                                VStack(alignment: .leading) {
                                    Text(monthFormatter.string(from: monthDate))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: calculateMonthWidth(for: monthDate, cellSize: multiMonthCellSize), alignment: .leading)
                                        .padding(.bottom, 4)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.leading, 4)
                }
            }
            
            // Main heatmap grid
            HStack(alignment: .top, spacing: 0) {
                // Day of week labels
                VStack(alignment: .trailing, spacing: cellSpacing) {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .frame(width: 16, height: multiMonthCellSize) // 멀티 월 뷰 셀 크기 사용
                    }
                }
                .padding(.trailing, 4)
                
                // Scrollable heatmap grid
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: cellSpacing) {
                        ForEach(0..<numberOfMonths, id: \.self) { monthIndex in
                            if let monthDate = Calendar.current.date(byAdding: .month, value: monthIndex, to: startDate) {
                                VStack(spacing: cellSpacing) {
                                    monthHeatmapGrid(for: monthDate, cellSize: multiMonthCellSize) // 멀티 월 뷰 셀 크기 사용
                                }
                            }
                        }
                    }
                    .padding(.leading, 4)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func monthHeatmapGrid(for date: Date, cellSize: CGFloat) -> some View {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        // Calculate days in month
        let range = calendar.range(of: .day, in: .month, for: date)!
        let numDays = range.count
        
        // Get first day of month and its weekday
        let firstDay = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let firstWeekday = calendar.component(.weekday, from: firstDay) // 1 = Sunday, 7 = Saturday
        
        // 일요일=1, 월요일=2, ..., 토요일=7로 계산되므로 일요일(1)일 경우 0개, 월요일(2)일 경우 1개의 빈 셀 필요
        let emptyCellsCount = firstWeekday - 1
        
        // Create a grid of cells for this month
        return LazyVGrid(columns: columns, spacing: cellSpacing) {
            // Empty cells for padding before first day
            ForEach(0..<emptyCellsCount, id: \.self) { _ in
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: cellSize, height: cellSize)
            }
            
            // Day cells
            ForEach(1...numDays, id: \.self) { day in
                if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                    let dayCount = heatmapData[calendar.startOfDay(for: date)] ?? 0
                    dayCellView(day: day, count: dayCount, cellSize: cellSize)
                }
            }
        }
    }
    
    private func dayCellView(day: Int, count: Int, cellSize: CGFloat) -> some View {
        let color = colorForCount(count)
        
        return ZStack {
            Rectangle()
                .fill(color)
                .frame(width: cellSize, height: cellSize)
                .cornerRadius(2)
                .overlay(
                    count > 0 ? nil : 
                        Rectangle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        .cornerRadius(2)
                )
            
            if numberOfMonths == 1 {
                // Only show day numbers in single month view
                Text("\(day)")
                    .font(.system(size: max(9, cellSize * 0.4))) // 최소 9pt, 아니면 셀 크기의 40%
                    .foregroundColor(count > 1 ? .white : .primary)
            }
        }
    }
    
    private func calculateMonthWidth(for date: Date, cellSize: CGFloat) -> CGFloat {
        let calendar = Calendar.current
        let firstDay = calendar.date(from: 
            DateComponents(
                year: calendar.component(.year, from: date),
                month: calendar.component(.month, from: date),
                day: 1
            )
        )!
        
        let firstWeekday = calendar.component(.weekday, from: firstDay) - 1
        let numWeeks = calendar.range(of: .weekOfMonth, in: .month, for: date)!.count
        
        // Width calculation based on cell size, spacing, and number of weeks
        return CGFloat(numWeeks) * (cellSize + cellSpacing) - cellSpacing
    }
    
    // MARK: - Color Logic
    
    private func colorForCount(_ count: Int) -> Color {
        switch count {
        case 0:
            return Color.gray.opacity(0.1)
        case 1:
            return Color.green.opacity(0.3)
        case 2:
            return Color.green.opacity(0.5)
        case 3:
            return Color.green.opacity(0.7)
        default:
            return Color.green.opacity(0.9)
        }
    }
    
    private func colorForLevel(_ level: Int) -> Color {
        switch level {
        case 0:
            return Color.gray.opacity(0.1)
        case 1:
            return Color.green.opacity(0.3)
        case 2:
            return Color.green.opacity(0.5)
        case 3:
            return Color.green.opacity(0.7)
        case 4:
            return Color.green.opacity(0.9)
        default:
            return Color.gray.opacity(0.1)
        }
    }
}

// MARK: - Preview
struct HeatmapCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample data for preview
        let sampleData: [Date: Int] = {
            var data: [Date: Int] = [:]
            let calendar = Calendar.current
            
            // Generate data for past 6 months
            let today = Date()
            
            for day in 0..<180 { // Roughly 6 months of data
                if let date = calendar.date(byAdding: .day, value: -day, to: today) {
                    // Random distribution with more 0s
                    let random = Int.random(in: 0...10)
                    var count = 0
                    
                    if random < 5 {
                        count = 0
                    } else if random < 7 {
                        count = 1
                    } else if random < 9 {
                        count = 2
                    } else if random < 10 {
                        count = 3
                    } else {
                        count = 4
                    }
                    
                    if count > 0 {
                        data[calendar.startOfDay(for: date)] = count
                    }
                }
            }
            
            return data
        }()
        
        Group {
            // Multi-month view
            HeatmapCalendarView(heatmapData: sampleData)
                .previewLayout(.sizeThatFits)
                .padding()
                .background(Color.gray.opacity(0.1))
                .previewDisplayName("Multi-month View")
            
            // Single month view (for home screen)
            HeatmapCalendarView(heatmapData: sampleData, startDate: Date(), numberOfMonths: 1)
                .frame(height: 200)
                .previewLayout(.sizeThatFits)
                .padding()
                .background(Color.gray.opacity(0.1))
                .previewDisplayName("Single Month View")
            
            // Compact view for profile
            HeatmapCalendarView(heatmapData: sampleData, numberOfMonths: 3, isCompactMode: true)
                .frame(height: 160)
                .previewLayout(.sizeThatFits)
                .padding()
                .background(Color.gray.opacity(0.1))
                .previewDisplayName("Compact Mode for Profile")
            
            // Dark mode
            HeatmapCalendarView(heatmapData: sampleData, numberOfMonths: 2)
                .previewLayout(.sizeThatFits)
                .padding()
                .background(Color.black)
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark Mode")
        }
    }
} 