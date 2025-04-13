import SwiftUI
import FirebaseFirestore // Import Firestore to use Timestamp
// import Kingfisher // Assuming you use Kingfisher for image loading

struct StoryView: View {
    @StateObject var viewModel: StoryViewModel
    @Environment(\.dismiss) var dismiss // To close the view
    @State private var progressValue: CGFloat = 0
    @State private var timer: Timer? = nil
    @State private var storyDuration: Double = 5.0 // 5 seconds per story
    
    // UI관련 상태 변수
    @State private var showCloseButton = true
    @State private var showControls = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Indicators
                HStack(spacing: 4) {
                    ForEach(0..<viewModel.stories.count, id: \.self) { index in
                        StoryProgressBar(
                            progress: index == viewModel.currentStoryIndex ? progressValue : (index < viewModel.currentStoryIndex ? 1 : 0)
                        )
                    }
                }
                .padding(.top, 10)
                .padding(.horizontal, 12)
                
                // User Header
                HStack(spacing: 12) {
                    // 프로필 이미지
                    if let profileUrl = URL(string: viewModel.user.profilePhoto), !viewModel.user.profilePhoto.isEmpty {
                        AsyncImage(url: profileUrl) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 36, height: 36)
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 36, height: 36)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // 사용자 정보
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.user.name)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            
                        if stories.indices.contains(viewModel.currentStoryIndex) {
                            let story = stories[viewModel.currentStoryIndex]
                            Text(story.createdAt.dateValue(), style: .relative)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    // 닫기 버튼
                    if showCloseButton {
                        Button {
                            stopTimer()
                            dismiss()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.4))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contentShape(Rectangle())
                    }
                }
                .padding(.top, 10)
                .padding(.horizontal, 16)
                
                // Main Content
                ZStack(alignment: .center) {
                    // 로딩, 에러, 컨텐츠 표시
                    if viewModel.isLoading {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Loading...")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.subheadline)
                                .padding(.top, 8)
                        }
                    } else if let errorMessage = viewModel.errorMessage {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.yellow)
                                .padding(.bottom, 8)
                            
                            Text("Error loading content")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.bottom, 4)
                            
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    } else if let workoutResult = viewModel.workoutResult {
                        WorkoutResultDetailView(result: workoutResult)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    } else {
                        Text("No workout data available")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.body)
                    }
                    
                    // 좌우 탭 영역 (항상 존재)
                    HStack(spacing: 0) {
                        // 이전 스토리 영역
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                resetProgressAndNavigate(isPrevious: true)
                            }
                            .frame(width: UIScreen.main.bounds.width * 0.3)
                        
                        // 중앙 영역 (일시정지/재생)
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onLongPressGesture(minimumDuration: .infinity, pressing: { isPressing in
                                if isPressing {
                                    // Long press started - pause timer
                                    stopTimer()
                                    withAnimation {
                                        showControls = false
                                    }
                                } else {
                                    // Long press ended - resume timer
                                    startTimer()
                                    withAnimation {
                                        showControls = true
                                    }
                                }
                            }) {
                                // This won't be triggered due to minimumDuration: .infinity
                            }
                            .frame(width: UIScreen.main.bounds.width * 0.4)
                        
                        // 다음 스토리 영역
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                resetProgressAndNavigate(isPrevious: false)
                            }
                            .frame(width: UIScreen.main.bounds.width * 0.3)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .statusBar(hidden: true)
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // 타이머 관련 메소드
    private func startTimer() {
        stopTimer() // 기존 타이머가 있다면 중지
        
        // 새 타이머 시작
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            if progressValue < 1.0 {
                progressValue += 0.05 / storyDuration
            } else {
                resetProgressAndNavigate(isPrevious: false)
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func resetProgressAndNavigate(isPrevious: Bool) {
        stopTimer()
        progressValue = 0
        
        if isPrevious {
            viewModel.previousStory()
        } else {
            if viewModel.currentStoryIndex < viewModel.stories.count - 1 {
                viewModel.advanceStory()
            } else {
                dismiss() // 마지막 스토리이므로 뷰 닫기
            }
        }
        
        startTimer()
    }
    
    // 현재 스토리 배열에 쉽게 접근하기 위한 속성
    private var stories: [Story] {
        viewModel.stories
    }
}

// 개선된 스토리 프로그래스 바
struct StoryProgressBar: View {
    var progress: CGFloat // 0.0 to 1.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 배경 바
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: geometry.size.width, height: 2)
                
                // 진행 바
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: geometry.size.width * progress, height: 2)
            }
        }
        .frame(height: 2)
    }
}

// 워크아웃 결과 상세 뷰 (기존 뷰에서 디자인 개선)
struct WorkoutResultDetailView: View {
    let result: WorkoutResultModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 헤더: 워크아웃 제목 및 요약
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        
                        Text("Workout")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Text("Total Duration: \(formatDuration(result.duration))")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 4)
                
                // 구분선
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.clear, .white.opacity(0.3), .clear]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: 1)
                    .padding(.vertical, 4)
                
                // 운동 목록
                VStack(alignment: .leading, spacing: 16) {
                    Text("Exercises")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    ForEach(result.exercises, id: \.self) { exercise in
                        ExerciseCard(exercise: exercise)
                    }
                }
                
                // 노트 (있는 경우)
                if let notes = result.notes, !notes.isEmpty {
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.clear, .white.opacity(0.3), .clear]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(height: 1)
                        .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundColor(.yellow)
                            Text("Notes")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 4)
                    }
                }
            }
            .padding(.vertical, 16)
        }
    }
    
    // Helper function to format duration
    private func formatDuration(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// 운동 카드 (각 운동 표시)
struct ExerciseCard: View {
    let exercise: ExerciseResultModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 운동 이름
            Text(exercise.exerciseName)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            // 세트 정보
            VStack(alignment: .leading, spacing: 4) {
                ForEach(exercise.sets.indices, id: \.self) { index in
                    let set = exercise.sets[index]
                    HStack {
                        Text("Set \(index + 1)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 55, alignment: .leading)
                        
                        Text("\(set.Reps) reps")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        if let weight = set.Weight {
                            Text("•")
                                .foregroundColor(.white.opacity(0.5))
                            Text("\(weight, specifier: "%.1f") kg")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(.leading, 8)
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}

// Preview Provider
struct StoryView_Previews: PreviewProvider {
    static var previews: some View {
        let mockUser = User(uid: "previewUser1", email: "preview@example.com", name: "Preview User")
        
        // Create mock workout result data
        let mockSet1 = SetResultModel(Reps: 10, Weight: 50.0)
        let mockSet2 = SetResultModel(Reps: 8, Weight: 55.0)
        let mockExercise1 = ExerciseResultModel(exerciseName: "ベンチプレス", setsCompleted: 2, sets: [mockSet1, mockSet2])
        let mockExercise2 = ExerciseResultModel(exerciseName: "ショルダープレス", setsCompleted: 3, sets: [mockSet1, mockSet1, mockSet1])
        let mockWorkoutResult = WorkoutResultModel(
            id: "mockResult1",
            duration: 2700,
            restTime: nil,
            workoutID: "origWorkout1",
            exercises: [mockExercise1, mockExercise2],
            notes: "今日のトレーニングは順調でした！",
            createdAt: Timestamp(date: Date())
        )
        
        let mockStories = [
            Story(id: "story1", userId: "previewUser1", photo: nil, expireAt: Timestamp(date: Date(timeIntervalSinceNow: 3600)), isExpired: false, visibility: 1, workoutId: "mockResult1", createdAt: Timestamp(date: Date())),
            Story(id: "story2", userId: "previewUser1", photo: nil, expireAt: Timestamp(date: Date(timeIntervalSinceNow: 7200)), isExpired: false, visibility: 1, workoutId: "anotherResultId", createdAt: Timestamp(date: Date()))
        ]
        
        let viewModel = StoryViewModel(user: mockUser, stories: mockStories)
        viewModel.workoutResult = mockWorkoutResult
        
        return StoryView(viewModel: viewModel)
    }
} 
