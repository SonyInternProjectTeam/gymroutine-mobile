import SwiftUI

struct GroupGoalCreateView: View {
    let groupId: String
    @StateObject private var viewModel = GroupGoalCreateViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 목표 기본 정보
                    VStack(alignment: .leading, spacing: 16) {
                        Text("目標の基本情報")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("目標名")
                                .font(.headline)
                            
                            TextField("目標名を入力してください", text: $viewModel.title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("説明 (任意)")
                                .font(.headline)
                            
                            TextField("目標の説明を入力してください", text: $viewModel.description, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 목표 유형 선택
                    VStack(alignment: .leading, spacing: 16) {
                        Text("目標タイプ")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(GroupGoalType.allCases, id: \.self) { goalType in
                                ZStack {
                                    Button(action: {
                                        // 개발중인 목표 유형은 선택할 수 없게 함
                                        if goalType != .workoutDuration && goalType != .weightLifted {
                                            viewModel.selectedGoalType = goalType
                                        }
                                    }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: goalType.iconName)
                                                .font(.title2)
                                                .foregroundColor(viewModel.selectedGoalType == goalType ? .white : .blue)
                                            
                                            Text(goalType.displayName)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(viewModel.selectedGoalType == goalType ? .white : .primary)
                                            
                                            Text(goalType.defaultUnit)
                                                .font(.caption)
                                                .foregroundColor(viewModel.selectedGoalType == goalType ? .white.opacity(0.8) : .secondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(viewModel.selectedGoalType == goalType ? Color(.systemBlue) : Color(.systemGray6))
                                        .cornerRadius(12)
                                    }
                                    .disabled(goalType == .workoutDuration || goalType == .weightLifted)
                                    
                                    // 개발중 오버레이
                                    if goalType == .workoutDuration || goalType == .weightLifted {
                                        VStack(spacing: 4) {
                                            Image(systemName: "wrench.and.screwdriver")
                                                .font(.title3)
                                                .foregroundColor(.orange)
                                            
                                            Text("開発中です")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.orange)
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(Color.black.opacity(0.7))
                                        .cornerRadius(12)
                                        .allowsHitTesting(false)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 목표 수치 설정
                    VStack(alignment: .leading, spacing: 16) {
                        Text("目標数値")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack {
                            Text("目標値:")
                                .font(.headline)
                            
                            Spacer()
                            
                            TextField("数値を入力", value: $viewModel.targetValue, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                                .frame(width: 100)
                            
                            Text(viewModel.selectedGoalType.defaultUnit)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 기간 설정
                    VStack(alignment: .leading, spacing: 16) {
                        Text("期間設定")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            DatePicker("開始日", selection: $viewModel.startDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .onChange(of: viewModel.startDate) { _ in
                                    // 시작일 변경 시 반복 설정에 따라 종료일 조정
                                    viewModel.updateEndDateForRepeat()
                                }
                            
                            DatePicker("終了日", selection: $viewModel.endDate, in: viewModel.startDate..., displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .disabled(viewModel.selectedRepeatOption != .none) // 반복 설정 시 수동 편집 비활성화
                        }
                        
                        // 반복 설정 섹션
                        VStack(alignment: .leading, spacing: 16) {
                            Text("反復設定")
                                .font(.headline)
                            
                            // 반복 옵션 카드 형태로 변경
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(RepeatOption.allCases, id: \.self) { option in
                                    Button(action: {
                                        viewModel.selectedRepeatOption = option
                                    }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: option.iconName)
                                                .font(.title3)
                                                .foregroundColor(viewModel.selectedRepeatOption == option ? .white : .accentColor)
                                            
                                            Text(option.displayName)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(viewModel.selectedRepeatOption == option ? .white : .primary)
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 70)
                                        .background(viewModel.selectedRepeatOption == option ? Color(.systemBlue) : Color(.systemBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(viewModel.selectedRepeatOption == option ? Color(.systemBlue) : Color(.systemGray4), lineWidth: viewModel.selectedRepeatOption == option ? 2 : 1)
                                        )
                                        .cornerRadius(10)
                                    }
                                }
                            }
                            
                            // 반복 횟수 설정 (반복 옵션이 선택된 경우에만 표시)
                            if viewModel.selectedRepeatOption != .none {
                                VStack(spacing: 12) {
                                    HStack {
                                        Image(systemName: "repeat")
                                            .foregroundColor(.accentColor)
                                        
                                        Text("反復回数")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                    }
                                    
                                    // 반복 횟수 스테퍼
                                    HStack {
                                        Text("回数:")
                                            .font(.subheadline)
                                        
                                        Spacer()
                                        
                                        Stepper(value: $viewModel.repeatCount, in: 1...12) {
                                            VStack(spacing: 4) {
                                                Text("\(viewModel.repeatCount)")
                                                    .font(.title2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.accentColor)
                                                
                                                Text(viewModel.selectedRepeatOption == .weekly ? "週間" : "ヶ月")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color(.systemBlue).opacity(0.1))
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                                .padding(.top, 8)
                                .transition(.opacity.combined(with: .scale))
                            }
                        }
                        
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.accentColor)
                            
                            Text("期間: \(viewModel.durationText)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Spacer()
                    
                    // 생성 버튼
                    Button(action: {
                        viewModel.createGoal(groupId: groupId)
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text("目標を作成")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.canCreateGoal ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!viewModel.canCreateGoal || viewModel.isLoading)
                }
                .padding()
            }
            .navigationTitle("目標作成")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("成功", isPresented: .constant(viewModel.showSuccessAlert)) {
                Button("OK") {
                    viewModel.showSuccessAlert = false
                    dismiss()
                }
            } message: {
                Text("目標が正常に作成されました！")
            }
        }
        .onAppear {
            viewModel.initializeDates()
        }
    }
}

extension GroupGoalType {
    var iconName: String {
        switch self {
        case .workoutCount:
            return "figure.run"
        case .workoutDuration:
            return "clock"
        case .weightLifted:
            return "scalemass"
        }
    }
}

#Preview {
    GroupGoalCreateView(groupId: "sample-group-id")
} 