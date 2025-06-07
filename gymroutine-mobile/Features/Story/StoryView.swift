import SwiftUI
import FirebaseFirestore // Import Firestore to use Timestamp
// import Kingfisher // Assuming you use Kingfisher for image loading

struct StoryView: View {
    @ObservedObject var viewModel: StoryViewModel
    @Environment(\.dismiss) var dismiss // To close the view
    private let analyticsService = AnalyticsService.shared
    
    // UI관련 상태 변수
    @State private var showCloseButton = true
    @State private var showControls = true
    
    // Analytics 관련 상태 변수
    @State private var storyViewStartTime = Date()
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack(spacing: 16) {
                    progressBarBox
                    
                    userHeaderBox
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.black.opacity(0.3), .clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                contentBox()
            }
            .background(Color.gray.opacity(0.1))
            .statusBar(hidden: true)
            .edgesIgnoringSafeArea(.all)
            .onReceive(viewModel.viewDismissalModePublisher) { shouldDismiss in
                if shouldDismiss {
                    dismiss()
                }
            }
            .onAppear {
                // Log screen view
                analyticsService.logScreenView(screenName: "Story")
                
                // Start tracking story view time
                storyViewStartTime = Date()
            }
            .onDisappear {
                // Log story viewed when view disappears
                if viewModel.stories.indices.contains(viewModel.currentStoryIndex) {
                    let story = viewModel.stories[viewModel.currentStoryIndex]
                    let viewDuration = Date().timeIntervalSince(storyViewStartTime)
                    analyticsService.logStoryViewed(
                        storyId: story.id ?? "unknown",
                        authorId: story.userId,
                        viewDuration: viewDuration
                    )
                }
            }
            .onChange(of: viewModel.currentStoryIndex) { oldValue, newValue in
                // Log previous story viewed duration when story changes
                if viewModel.stories.indices.contains(oldValue) {
                    let story = viewModel.stories[oldValue]
                    let viewDuration = Date().timeIntervalSince(storyViewStartTime)
                    analyticsService.logStoryViewed(
                        storyId: story.id ?? "unknown",
                        authorId: story.userId,
                        viewDuration: viewDuration
                    )
                }
                
                // Reset timer for new story
                storyViewStartTime = Date()
            }
        }
    }
    
    @ViewBuilder
    private func contentBox() -> some View {
        Group {
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    
                    Text("Loading...")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 45))
                        .foregroundColor(.yellow)
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            } else if let workoutResult = viewModel.workoutResult {
                ScrollView(showsIndicators: false) {
                    WorkoutResultDetailView(result: workoutResult, viewModel: viewModel)
                }
                .padding()
            } else {
                Text("ワークアウトデータが見つかりません。")
                    .foregroundStyle(.secondary)
                    .font(.body)
            }
        }
        .frame(maxHeight: .infinity)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    let dragDistance = abs(value.translation.width) + abs(value.translation.height)
                    if dragDistance < 16 { // ほぼ動いてない＝タップ判定
                        let tapLocation = value.startLocation
                        let screenWidth = UIScreen.main.bounds.width
                        let tapRatio = tapLocation.x / screenWidth

                        if tapRatio < 0.2 {
                            viewModel.previousStory()
                        } else if tapRatio > 0.8 {
                            viewModel.advanceStory()
                        }
                    }
                }
        )
    }
    
    // Progress Indicators
    private var progressBarBox: some View {
        HStack(spacing: 4) {
            ForEach(0..<viewModel.stories.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 6)
                    .fill(index < viewModel.currentStoryIndex ? .white : .secondary)
                    .frame(height: 6)
            }
        }
    }
    private var userHeaderBox: some View {
        HStack(spacing: 12) {
            NavigationLink(
                destination: ProfileView(user: viewModel.user, router: nil)
                , label: {
                    HStack {
                        ProfileIcon(profileUrl: viewModel.user.profilePhoto, size: .small)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.user.name)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                
                            if stories.indices.contains(viewModel.currentStoryIndex) {
                                let story = stories[viewModel.currentStoryIndex]
                                Text(story.createdAt.dateValue(), style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
            })
            .tint(.primary)
            
            Spacer()
            
            // 닫기 버튼
            if showCloseButton {
                Button {
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
    }
    
    // 현재 스토리 배열에 쉽게 접근하기 위한 속성
    private var stories: [Story] {
        viewModel.stories
    }
}

// 워크아웃 결과 상세 뷰 (기존 뷰에서 디자인 개선)
struct WorkoutResultDetailView: View {
    let result: WorkoutResultModel
    @ObservedObject var viewModel: StoryViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 헤더: 워크아웃 제목 및 요약
            totalSummaryBox
            
            workoutTimeBox
            
            CustomDivider()
            
            // 운동 목록
            VStack(alignment: .leading, spacing: 16) {
                
                Label("エクササイズ", systemImage: "flame.fill")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                ForEach(result.exercises.indices, id: \.self) { index in
                    ExerciseResultCell(
                        exerciseIndex: index + 1,
                        exercise: result.exercises[index]
                    )
                }
            }
            
            // 노트 (있는 경우)
            if let notes = result.notes, !notes.isEmpty {
                
                CustomDivider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("ノート", systemImage: "note.text")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(notes)
                        .font(.subheadline)
                        .padding(.horizontal, 4)
                }
            }
        }
    }
    
    private var totalSummaryBox: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                Label("総重量", systemImage: "figure.strengthtraining.traditional")
                    .font(.headline)
                
                HStack(alignment: .lastTextBaseline) {
                    Text("\(viewModel.totalVolume)")
                        .font(.largeTitle).bold()
                        .foregroundStyle(.main)
                        .lineLimit(1)
                        .minimumScaleFactor(0.1)
                    Text("kg")
                        .fontWeight(.semibold)
                }
                .hAlign(.center)
            }
            .padding()
            .background()
            .clipShape(.rect(cornerRadius: 8))
            .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1.5)
            
            VStack(alignment: .leading, spacing: 16) {
                Label("合計セット数", systemImage: "list.number.rtl")
                    .font(.headline)
                
                HStack(alignment: .lastTextBaseline) {
                    Text("\(viewModel.totalSets)")
                        .font(.largeTitle).bold()
                        .foregroundStyle(.main)
                    Text("回")
                        .fontWeight(.semibold)
                }
                .hAlign(.center)
            }
            .padding()
            .background()
            .clipShape(.rect(cornerRadius: 8))
            .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1.5)
        }
    }
    
    private var workoutTimeBox: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                Label("運動時間", systemImage: "figure.run")
                    .font(.headline)
                
                Group {
                    Text(viewModel.formattedTime(from: result.duration))
                }
                .font(.title2).bold()
                .foregroundStyle(.main)
                .hAlign(.center)
            }
            .padding()
            .background()
            .clipShape(.rect(cornerRadius: 8))
            .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1.5)
            
            VStack(alignment: .leading, spacing: 16) {
                Label("休憩時間", systemImage: "cup.and.saucer")
                    .font(.headline)
                
                Group {
                    if let restTime = result.restTime {
                        Text(viewModel.formattedTime(from: restTime))
                    } else { Text("--") }
                }
                .font(.title2).bold()
                .foregroundStyle(.main)
                .hAlign(.center)
            }
            .padding()
            .background()
            .clipShape(.rect(cornerRadius: 8))
            .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1.5)
        }
    }
    
    @ViewBuilder
    private func timeCell(title: String, value: Int) -> some View {
        VStack(spacing: 16) {
            Text(title)
                .foregroundStyle(.secondary)
                .font(.caption)
                .hAlign(.leading)
            
            Text(viewModel.formattedTime(from: value))
                .font(.title2.bold())
                .hAlign(.center)
        }
        .padding()
        .frame(height: 108)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1.5)
    }
}

// Preview Provider
struct StoryView_Previews: PreviewProvider {
    static var previews: some View {
        let mockUser = User(uid: "previewUser1", email: "preview@example.com", name: "Preview User")
        
        // Create mock workout result data
        let mockSet1 = SetResultModel(Reps: 10, Weight: 50.0)
        let mockSet2 = SetResultModel(Reps: 8, Weight: 55.0)
        let mockExercise1 = ExerciseResultModel(exerciseName: "ベンチプレス", key: "Bench Press", setsCompleted: 2, sets: [mockSet1, mockSet2])
        let mockExercise2 = ExerciseResultModel(exerciseName: "ショルダープレス", key: "Shoulder Press", setsCompleted: 3, sets: [mockSet1, mockSet1, mockSet1])
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
