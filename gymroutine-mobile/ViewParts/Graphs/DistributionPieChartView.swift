import SwiftUI
import Charts

/// 運動部位別分布をパイチャートで表示するビュー
struct DistributionPieChartView: View {
    let distribution: ExerciseDistribution
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("運動部位分布")
                .font(.headline)
            
            if distribution.isEmpty {
                Text("データが不足しています")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 150, alignment: .center)
            } else {
                Chart {
                    ForEach(AnalyticsService.shared.getDistributionChartData(from: distribution), id: \.0) { item in
                        SectorMark(
                            angle: .value("割合", item.1),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .cornerRadius(5)
                        .foregroundStyle(by: .value("部位", item.0))
                        .annotation(position: .overlay) {
                            Text("\(Int(item.1))%")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(height: 200)
                .chartLegend(position: .bottom, alignment: .center, spacing: 10)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    // サンプルデータ
    let sampleDistribution: ExerciseDistribution = [
        "chest": 30,
        "back": 25,
        "legs": 20,
        "shoulder": 15,
        "arm": 10
    ]
    
    return DistributionPieChartView(distribution: sampleDistribution)
        .padding()
        .previewLayout(.sizeThatFits)
} 