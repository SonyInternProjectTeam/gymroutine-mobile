import SwiftUI

/// 運動遵守率を円形チャートで表示するビュー
struct AdherenceCircleChartView: View {
    let adherence: WorkoutAdherence
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("運動達成率")
                .font(.headline)
            
            HStack(spacing: 20) {
                AdherenceCircleView(
                    title: "今週",
                    percentage: adherence.thisWeek,
                    color: .blue
                )
                
                AdherenceCircleView(
                    title: "今月",
                    percentage: adherence.thisMonth,
                    color: .green
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

/// 遵守率円形チャートの個別アイテムビュー
struct AdherenceCircleView: View {
    let title: String
    let percentage: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: CGFloat(percentage) / 100)
                    .stroke(color, lineWidth: 10)
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                
                Text("\(percentage)%")
                    .font(.headline)
                    .bold()
            }
        }
    }
}

#Preview {
    // サンプルデータ
    let sampleAdherence = WorkoutAdherence(thisWeek: 60, thisMonth: 75)
    
    return AdherenceCircleChartView(adherence: sampleAdherence)
        .padding()
        .previewLayout(.sizeThatFits)
} 