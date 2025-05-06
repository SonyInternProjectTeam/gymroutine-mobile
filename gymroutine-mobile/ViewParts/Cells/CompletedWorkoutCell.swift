import SwiftUI
import FirebaseFirestore

struct CompletedWorkoutCell: View {
    let result: WorkoutResult
    let workoutName: String
    
    var body: some View {
        NavigationLink(destination: CompletedWorkoutDetailView(resultId: result.id ?? "")) {
            HStack(spacing: 8) {
                ExerciseImageCell(imageName: result.exercises?.first?.key)
                    .frame(width: 48, height: 48)
                
                VStack(alignment: .leading, spacing: 8) {
                    if let completedAt = result.createdAt?.dateValue() {
                        Text("完了: \(completedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(workoutName)
                        .font(.system(size: 16, weight: .bold))
                        .tint(.primary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "chevron.right")
                    .resizable()
                    .tint(.secondary)
                    .frame(width: 6, height: 12)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(.background, in: RoundedRectangle(cornerRadius: 8))
            .compositingGroup()
            .shadow(color: .black.opacity(0.08), radius: 4)
        }
        .buttonStyle(.plain)
    }
}

struct CompletedWorkoutCell_Previews: PreviewProvider {
    static var previews: some View {
        CompletedWorkoutCell(
            result: WorkoutResult(
                id: "test-id",
                userId: "user-id",
                workoutId: "workout-id",
                createdAt: Timestamp(date: Date())
              
            ),
            workoutName: "Push Day"
        )
    }
} 
