import SwiftUI

/// ユーザーのお気に入り運動を表示するビュー
struct FavoriteExercisesView: View {
    let exercises: [FavoriteExercise]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("お気に入り運動")
                .font(.headline)
            
            if exercises.isEmpty {
                Text("データが不足しています")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100, alignment: .center)
            } else {
                VStack(spacing: 8) {
                    ForEach(exercises, id: \.name) { exercise in
                        ExerciseRowView(exercise: exercise)
                        
                        if exercise.name != exercises.last?.name {
                            Divider()
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

/// 個別の運動項目を表示する行ビュー
struct ExerciseRowView: View {
    let exercise: FavoriteExercise
    
    var body: some View {
        HStack {
            Image(systemName: "dumbbell.fill")
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("平均: \(String(format: "%.1f", exercise.avgReps))回 × \(String(format: "%.1f", exercise.avgWeight))kg")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    // サンプルデータ
    let sampleExercises: [FavoriteExercise] = [
        FavoriteExercise(name: "ベンチプレス", avgReps: 8.5, avgWeight: 70.0),
        FavoriteExercise(name: "スクワット", avgReps: 10.0, avgWeight: 100.0),
        FavoriteExercise(name: "ラットプルダウン", avgReps: 12.0, avgWeight: 55.0)
    ]
    
    return FavoriteExercisesView(exercises: sampleExercises)
        .padding()
        .previewLayout(.sizeThatFits)
} 