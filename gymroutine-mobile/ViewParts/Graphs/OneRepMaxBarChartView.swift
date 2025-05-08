import SwiftUI

/// 1回最大重量 (1RM) 情報をバーチャートで表示するビュー
struct OneRepMaxBarChartView: View {
    let oneRepMax: OneRepMaxInfo
    @State private var showingOneRMInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("1回最大重量 (1RM)")
                    .font(.headline)
                
                Button(action: {
                    showingOneRMInfo = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                }
                .alert("1RMの計算方法", isPresented: $showingOneRMInfo) {
                    Button("確認", role: .cancel) {}
                } message: {
                    Text("1RM(One-Rep Max)は各エクササイズで持ち上げることができる最大の重量を意味します。\n\n各エクササイズごとに、これまで記録したセットの中で最も高い重量を表示します。")
                }
            }
            
            if oneRepMax.isEmpty {
                Text("データが不足しています")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100, alignment: .center)
            } else {
                let sorted = oneRepMax.sorted { $0.value > $1.value }
                
                VStack(spacing: 12) {
                    ForEach(sorted.prefix(4), id: \.key) { (exercise, weight) in
                        OneRepMaxBarView(
                            exercise: exercise,
                            weight: weight,
                            maxWeight: sorted.first?.value ?? 0
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

/// 1RMバーチャートの個別アイテムビュー
struct OneRepMaxBarView: View {
    let exercise: String
    let weight: Double
    let maxWeight: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(exercise.capitalized)
                .font(.subheadline)
                .fontWeight(.medium)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 最大重量を基準に正規化
                    let normalizedWidth = maxWeight > 0 
                        ? (weight / maxWeight) * geometry.size.width
                        : 0
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: geometry.size.width, height: 20)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: normalizedWidth, height: 20)
                        .cornerRadius(4)
                    
                    Text("\(String(format: "%.1f", weight)) kg")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.leading, 8)
                }
            }
            .frame(height: 20)
        }
    }
}

#Preview {
    // サンプルデータ
    let sampleOneRepMax: OneRepMaxInfo = [
        "ベンチプレス": 80.5,
        "スクワット": 120.3,
        "デッドリフト": 140.8,
        "ショルダープレス": 60.2
    ]
    
    return OneRepMaxBarChartView(oneRepMax: sampleOneRepMax)
        .padding()
        .previewLayout(.sizeThatFits)
} 