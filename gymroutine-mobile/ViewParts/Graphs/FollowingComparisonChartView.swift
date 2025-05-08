import SwiftUI

/// フォロー中のユーザーとの運動比較を表示するビュー
struct FollowingComparisonChartView: View {
    let comparison: FollowingComparison
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("フォロー中との比較")
                .font(.headline)
            
            HStack(spacing: 20) {
                ComparisonItemView(
                    title: "自分", 
                    value: comparison.user,
                    color: .blue
                )
                
                ComparisonItemView(
                    title: "フォロー中平均", 
                    value: comparison.followingAvg,
                    color: .green
                )
            }
            .padding(.vertical, 8)
            
            Text(UserAnalyticsService.shared.getFollowingComparisonString(from: comparison))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

/// 比較項目を表示するアイテムビュー
struct ComparisonItemView: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text("回/週")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    // サンプルデータ
    let sampleComparison = FollowingComparison(user: 4, followingAvg: 3)
    
    return FollowingComparisonChartView(comparison: sampleComparison)
        .padding()
        .previewLayout(.sizeThatFits)
} 