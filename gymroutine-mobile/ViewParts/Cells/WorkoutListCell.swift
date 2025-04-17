import SwiftUI

struct WorkoutListCell: View {
    let index: Int
    let exercise: WorkoutExercise
    let showDragHandle: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // 인덱스 원형 표시
            ZStack {
                Circle()
                    .fill(Color.main.opacity(0.3))
                    .frame(width: 38, height: 38)
                
                Text("\(index)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.main)
            }
            
            // 운동 이미지 및 설명
            HStack {
                // 이미지
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    ExerciseImageCell(imageName: exercise.name)
                        .frame(width: 46, height: 46)
                }
                
                // 운동 이름
                Text(LocalizedStringKey(exercise.name))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 부위 표시
                HStack {
                    Text(LocalizedStringKey(exercise.part))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // 드래그 핸들 (선택적)
                if showDragHandle {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.leading, 8)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
    }
}

struct WorkoutListCell_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 10) {
            WorkoutListCell(
                index: 1,
                exercise: WorkoutExercise(
                    name: "Shoulder Press",
                    part: "shoulder",
                    sets: [ExerciseSet(reps: 12, weight: 20)]
                ),
                showDragHandle: true
            )
            
            WorkoutListCell(
                index: 2,
                exercise: WorkoutExercise(
                    name: "Bench Press",
                    part: "chest",
                    sets: [ExerciseSet(reps: 10, weight: 60)]
                ),
                showDragHandle: false
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
} 