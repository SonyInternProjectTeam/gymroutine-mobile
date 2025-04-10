//
//  WorkoutSessionView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/04/03.
//

import SwiftUI

// 스크롤 위치 추적을 위한 PreferenceKey
struct ViewOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct WorkoutSessionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: WorkoutSessionViewModel
    @Namespace private var scrollNamespace
    var onEndWorkout: (() -> Void)? = nil // 워크아웃 종료 콜백
    
    init(viewModel: WorkoutSessionViewModel, onEndWorkout: (() -> Void)? = nil) {
        print("📱 WorkoutSessionView 초기화됨")
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onEndWorkout = onEndWorkout
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 타이머 영역
            timerBox
            
            // 뷰 모드 전환 버튼
            HStack {
                Spacer()
                Button(action: { 
                    withAnimation {
                        viewModel.toggleViewMode()
                    }
                }) {
                    HStack {
                        Image(systemName: viewModel.isDetailView ? "list.bullet" : "1.square")
                        Text(viewModel.isDetailView ? "リスト表示" : "詳細表示")
                            .font(.footnote)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .cornerRadius(16)
                }
                .padding(.trailing)
            }
            .padding(.vertical, 4)
            .background(Color(UIColor.systemBackground))
            
            // 운동 영역 (상세 보기 또는 리스트 보기)
            if viewModel.isDetailView {
                detailExerciseView
                    .transition(.opacity)
            } else {
                listExercisesView
                    .transition(.opacity)
            }
            
            // 하단 네비게이션
            bottomNavigationBox
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { 
                    // 모달 닫기 - 워크아웃은 계속 진행
                    dismiss() 
                }) {
                    Text("最小化")
                        .foregroundStyle(.blue)
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("ワークアウト")
                    .font(.headline)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { 
                    // 워크아웃 종료
                    onEndWorkout?()
                    dismiss()
                }) {
                    Text("終了")
                        .foregroundStyle(.red)
                }
            }
        }
        .overlay {
            if viewModel.isRestTimerActive {
                restTimerOverlay
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: viewModel.isRestTimerActive)
        .animation(.easeInOut, value: viewModel.isDetailView)
        .animation(.easeInOut, value: viewModel.currentExerciseIndex)
        .animation(.easeInOut, value: viewModel.currentSetIndex)
    }
    
    private var timerBox: some View {
        VStack(spacing: 8) {
            Text("タイム")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(viewModel.minutes)")
                    .font(.system(size: 40, weight: .bold))
                Text(":")
                    .font(.system(size: 40, weight: .bold))
                Text("\(String(format: "%02d", viewModel.seconds))")
                    .font(.system(size: 40, weight: .bold))
            }
            
            // 진행 표시 - 점 대신 진행 바와 체크 표시로 변경
            if viewModel.isDetailView {
                exerciseProgressIndicator
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
    
    // 진행 바 너비 계산
    private func getProgressWidth(totalWidth: CGFloat) -> CGFloat {
        // 전체 운동 진행률을 기반으로 너비 계산
        return CGFloat(viewModel.totalWorkoutProgress) * totalWidth
    }
    
    // 운동 진행 표시기 - 진행 바와 체크 표시
    private var exerciseProgressIndicator: some View {
        VStack(spacing: 8) {
            // 진행 바
            progressBar
                .padding(.vertical, 4)
            
            // 운동 체크 표시
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(0..<viewModel.exercises.count, id: \.self) { index in
                            VStack(spacing: 4) {
                                // 체크 표시 또는 숫자
                                if isExerciseCompleted(index: index) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(.green)
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(index == viewModel.currentExerciseIndex ? .blue : .gray.opacity(0.3))
                                            .frame(width: 28, height: 28)
                                        
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                    }
                                }
                                
                                // 운동 이름
                                Text(viewModel.exercises[index].name)
                                    .font(.caption)
                                    .foregroundStyle(index == viewModel.currentExerciseIndex ? .primary : .secondary)
                                    .lineLimit(1)
                            }
                            .id(index)
                            .frame(width: 70)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(index == viewModel.currentExerciseIndex ? Color.blue.opacity(0.1) : Color.clear)
                            .cornerRadius(8)
                            .onTapGesture {
                                withAnimation {
                                    viewModel.currentExerciseIndex = index
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.vertical, 4)
                .onAppear {
                    // 현재 운동 인덱스로 스크롤
                    withAnimation {
                        proxy.scrollTo(viewModel.currentExerciseIndex, anchor: .center)
                    }
                }
                .onChange(of: viewModel.currentExerciseIndex) { newIndex in
                    // 인덱스가 변경될 때 해당 위치로 스크롤
                    withAnimation {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
        }
        .padding(.top, 8)
    }
    
    // 진행 바 컴포넌트
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 배경 바
                Rectangle()
                    .foregroundColor(.gray.opacity(0.2))
                    .frame(height: 6)
                    .cornerRadius(3)
                
                // 전체 진행 바
                Rectangle()
                    .foregroundColor(.blue)
                    .frame(width: getProgressWidth(totalWidth: geometry.size.width), height: 6)
                    .cornerRadius(3)
                
                // 현재 위치 표시
                let currentPosition = geometry.size.width * CGFloat(viewModel.progressUpToExercise(index: viewModel.currentExerciseIndex) + 
                                                             viewModel.currentExerciseProgress / CGFloat(viewModel.exercises.count))
                Circle()
                    .fill(.blue)
                    .frame(width: 12, height: 12)
                    .offset(x: currentPosition - 6) // 원 중앙에 위치하도록 보정
            }
        }
        .frame(height: 12) // 원이 들어갈 공간 고려
        .animation(.easeInOut, value: viewModel.currentExerciseIndex)
        .animation(.easeInOut, value: viewModel.currentExerciseProgress)
        .animation(.easeInOut, value: viewModel.totalWorkoutProgress)
    }
    
    // 운동 완료 여부 확인
    private func isExerciseCompleted(index: Int) -> Bool {
        // 해당 운동의 모든 세트가 완료되었는지 확인
        guard index < viewModel.exercises.count else { return false }
        let exercise = viewModel.exercises[index]
        
        for setIndex in 0..<exercise.sets.count {
            if !viewModel.isSetCompleted(exerciseIndex: index, setIndex: setIndex) {
                return false
            }
        }
        
        return exercise.sets.count > 0
    }
    
    // 단일 운동 상세 화면
    private var detailExerciseView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let exercise = viewModel.currentExercise {
                    // 운동 이름
                    Text(exercise.name)
                        .font(.title2.bold())
                        .padding(.top)
                    
                    // 운동 이미지와 진행률
                    exerciseProgressCircle(exercise: exercise)
                    
                    // 세트 정보
                    VStack(spacing: 0) {
                        HStack {
                            Text("メニュー")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            
                            Spacer()
                        }
                        
                        Divider()
                        
                        // 세트 헤더
                        HStack {
                            Text("セット")
                                .frame(width: 60, alignment: .leading)
                            Text("kg")
                                .frame(width: 60, alignment: .leading)
                            Text("レップ数")
                                .frame(width: 60, alignment: .leading)
                            Text("状態")
                                .frame(width: 60, alignment: .leading)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        
                        // 세트 목록
                        ForEach(Array(exercise.sets.enumerated()), id: \.offset) { setIndex, set in
                            HStack {
                                Text("\(setIndex + 1)")
                                    .frame(width: 60, alignment: .leading)
                                Text(String(format: "%.1f", set.weight))
                                    .frame(width: 60, alignment: .leading)
                                Text("\(set.reps)")
                                    .frame(width: 60, alignment: .leading)
                                
                                Button(action: {
                                    viewModel.toggleSetCompletionWithAutoAdvance(exerciseIndex: viewModel.currentExerciseIndex, setIndex: setIndex)
                                }) {
                                    Image(systemName: viewModel.isSetCompleted(exerciseIndex: viewModel.currentExerciseIndex, setIndex: setIndex) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(viewModel.isSetCompleted(exerciseIndex: viewModel.currentExerciseIndex, setIndex: setIndex) ? .green : .secondary)
                                }
                                .frame(width: 60, alignment: .leading)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(setIndex == viewModel.currentSetIndex ? Color.blue.opacity(0.1) : Color.clear)
                            
                            if setIndex < exercise.sets.count - 1 {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .background(Color(UIColor.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                } else {
                    Text("エクササイズがありません")
                        .foregroundStyle(.secondary)
                        .padding(.top, 100)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // 모든 운동 리스트 화면
    private var listExercisesView: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { index, exercise in
                        exerciseCard(exercise: exercise, index: index)
                            .id(index)
                            .opacity(viewModel.currentExerciseIndex == index ? 1.0 : 0.7)
                            .scaleEffect(viewModel.currentExerciseIndex == index ? 1.0 : 0.98)
                            .onTapGesture {
                                withAnimation {
                                    viewModel.currentExerciseIndex = index
                                    scrollProxy.scrollTo(index, anchor: .center)
                                }
                            }
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.currentExerciseIndex) { newIndex in
                withAnimation {
                    scrollProxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }
    
    private func exerciseCard(exercise: WorkoutExercise, index: Int) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // 순서 표시
                Text("\(index + 1)")
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(width: 24)
                
                // 운동 정보
                HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title2)
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text(exercise.name)
                        .font(.headline)
                }
                
                Spacer()
            }
            .padding()
            
            // 세트 목록
            VStack(spacing: 0) {
                // 헤더
                HStack {
                    Text("セット")
                        .frame(width: 60, alignment: .leading)
                    Text("kg")
                        .frame(width: 60, alignment: .leading)
                    Text("レップ数")
                        .frame(width: 60, alignment: .leading)
                    Text("状態")
                        .frame(width: 60, alignment: .leading)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                
                // 세트 리스트
                ForEach(Array(exercise.sets.enumerated()), id: \.offset) { setIndex, set in
                    HStack {
                        Text("\(setIndex + 1)")
                            .frame(width: 60, alignment: .leading)
                        Text(String(format: "%.1f", set.weight))
                            .frame(width: 60, alignment: .leading)
                        Text("\(set.reps)")
                            .frame(width: 60, alignment: .leading)
                        
                        Button(action: {
                            viewModel.toggleSetCompletion(exerciseIndex: index, setIndex: setIndex)
                        }) {
                            Image(systemName: viewModel.isSetCompleted(exerciseIndex: index, setIndex: setIndex) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(viewModel.isSetCompleted(exerciseIndex: index, setIndex: setIndex) ? .green : .secondary)
                        }
                        .frame(width: 60, alignment: .leading)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    if setIndex < exercise.sets.count - 1 {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var bottomNavigationBox: some View {
        HStack {
            Button(action: {
                if viewModel.isDetailView {
                    viewModel.moveToPreviousSet()
                } else {
                    viewModel.previousExercise()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                viewModel.addExercise()
            }) {
                Image(systemName: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(.blue)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Button(action: {
                if viewModel.isDetailView {
                    viewModel.moveToNextSet()
                } else {
                    viewModel.nextExercise()
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
    
    private var restTimerOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                Text("休憩時間")
                    .font(.title2)
                    .foregroundStyle(.white)
                
                Text("\(viewModel.remainingRestSeconds)")
                    .font(.system(size: 70, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("秒")
                    .font(.title3)
                    .foregroundStyle(.white)
                
                Button(action: {
                    viewModel.stopRestTimer()
                }) {
                    Text("スキップ")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(.blue)
                        .clipShape(Capsule())
                }
            }
            .padding(32)
            .background(.black.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
    
    // 詳細画面のエクササイズ画像と進行円形インジケーター
    private func exerciseProgressCircle(exercise: WorkoutExercise) -> some View {
        ZStack {
            // 背景の円
            Circle()
                .stroke(lineWidth: 20)
                .opacity(0.2)
                .foregroundColor(.blue)
            
            // 進行円
            Circle()
                .trim(from: 0.0, to: CGFloat(viewModel.currentExerciseProgress))
                .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                .foregroundColor(.blue)
                .rotationEffect(Angle(degrees: 270.0))
            
            // エクササイズ画像
            ExerciseImageCell(imageName: exercise.name)
                .frame(width: 120, height: 120)
        }
        .frame(width: 200, height: 200)
        .padding(.vertical, 20)
    }
    
    // 진행 원 애니메이션을 위한 키프레임 애니메이션
    @State private var animateProgress = false
    @State private var anchors: [String: UnitPoint] = [:]
}
