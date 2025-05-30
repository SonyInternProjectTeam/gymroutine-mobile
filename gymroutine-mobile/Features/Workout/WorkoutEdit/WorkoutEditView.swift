import SwiftUI

struct WorkoutEditView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var workoutDeleted: Bool
    @EnvironmentObject var detailViewModel: WorkoutDetailViewModel
    @StateObject var viewModel: WorkoutEditViewModel
    @State private var workoutName: String
    @State private var workoutNotes: String
    @State private var selectedDays: [String] = []
    @State private var routineToggle: Bool = false
    private let analyticsService = AnalyticsService.shared
    
    private let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    private let weekdaysLocalized = ["月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日", "日曜日"]
    
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    
    init(workout: Workout, workoutDeleted: Binding<Bool>) {
        let viewModel = WorkoutEditViewModel(workout: workout)
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._workoutName = State(initialValue: workout.name)
        self._workoutNotes = State(initialValue: workout.notes ?? "")
        self._selectedDays = State(initialValue: workout.scheduledDays)
        self._workoutDeleted = workoutDeleted
        self._routineToggle = State(initialValue: workout.isRoutine)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        nameBox
                        
                        notesBox
                        Toggle("ルーティン化", isOn: $routineToggle)
                        // ルーチン曜日（ルーチンの場合のみ表示）
                        if routineToggle {
                            routineDaysBox
                        }
                        deleteButtonSection
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.immediately)
                .background(Color.gray.opacity(0.1))
                .contentMargins(.top, 16)
                .contentMargins(.bottom, 80)
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            // ナビゲーションバー設定
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 左：キャンセルボタン
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                // 中央：タイトル
                ToolbarItem(placement: .principal) {
                    Text("ワークアウト編集")
                        .font(.headline)
                }
                
                // 右：保存ボタン
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        if selectedDays == [] && routineToggle {
                            viewModel.showRoutineAlert = true
                            return
                        }
                        Task {
                            await viewModel.saveWorkout(
                                name: workoutName, 
                                notes: workoutNotes.isEmpty ? nil : workoutNotes,
                                scheduledDays: selectedDays,
                                routine: routineToggle
                            )
                            detailViewModel.refreshWorkoutData()
                            dismiss()
                        }
                    }
                    .disabled(workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("ワークアウト削除確認", isPresented: $viewModel.showDeleteConfirmAlert) {
                Button("削除", role: .destructive) {
                    Task {
                        if await viewModel.deleteWorkout() {
                            workoutDeleted = true
                            dismiss()
                        }
                    }
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("「\(workoutName)」を完全に削除しますか？この操作は取り消せません。")
            }
            .alert("エラー", isPresented: $viewModel.showRoutineAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("ワークアウトを行う曜日を選択して下さい")
            }
            .onAppear {
                // Log screen view
                analyticsService.logScreenView(screenName: "WorkoutEdit")
            }
        }
    }
    
    private var nameBox: some View {
        VStack(alignment: .leading) {
            Text("ワークアウト名")
                .font(.headline)
            
            TextField("ワークアウト名を入力", text: $workoutName)
                .fieldBackground()
                .submitLabel(.done)
                .clipped()
                .shadow(radius: 1)
        }
    }
    
    private var notesBox: some View {
        VStack(alignment: .leading) {
            Text("メモ")
                .font(.headline)
            
            TextField(
                "メモを残す...",
                text: $workoutNotes,
                axis: .vertical
            )
            .submitLabel(.done)
            .frame(maxHeight: 248)
            .padding(12)
            .background(Color(UIColor.systemGray6))
            .clipShape(.rect(cornerRadius: 10))
            .clipped()
            .shadow(radius: 1)
        }
    }
    
    // ルーチン曜日選択
    private var routineDaysBox: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("トレーニング曜日")
                .font(.headline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: columns) {
                ForEach(0..<weekdays.count, id: \.self) { index in
                    HStack {
                        Image(systemName: selectedDays.contains(weekdays[index]) ? "checkmark" : "plus")
                        
                        Text(weekdaysLocalized[index])
                    }
                    .padding(12)
                    .background(selectedDays.contains(weekdays[index]) ? .main : .secondary.opacity(0.2))
                    .clipShape(.rect(cornerRadius: 8))
                    .onTapGesture {
                        withAnimation {
                            if let idx = selectedDays.firstIndex(of: weekdays[index]) {
                                selectedDays.remove(at: idx)
                            } else {
                                selectedDays.append(weekdays[index])
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.05), radius: 1, y: 1)
        }
    }
    
    // 新しい削除ボタンセクション
    private var deleteButtonSection: some View {
        VStack(spacing: 16) {
            Divider()
            Button(role: .destructive) {
                viewModel.showDeleteConfirmAlert = true // Show confirmation alert
            } label: {
                Label("ワークアウト削除", systemImage: "trash")
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .padding([.horizontal, .bottom]) // Add padding
        }
        .background(Color(UIColor.systemGray6))
    }
}

// プレビュー
struct WorkoutEditView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WorkoutEditView(workout: Workout(
                id: "preview",
                userId: "user1",
                name: "プレビューワークアウト",
                createdAt: Date(),
                notes: "プレビュー用メモ",
                isRoutine: true,
                scheduledDays: ["Monday", "Wednesday", "Friday"],
                exercises: [.mock(), .mock()]
            ), workoutDeleted: .constant(false))
        }
    }
} 
