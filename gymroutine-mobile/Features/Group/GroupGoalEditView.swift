import SwiftUI

struct GroupGoalEditView: View {
    let goal: GroupGoal
    let groupId: String
    @StateObject private var viewModel = GroupGoalEditViewModel()
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
                            
                            Text(goal.unit)
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
                                .disabled(true) // 편집 시 시작일은 변경 불가
                            
                            DatePicker("終了日", selection: $viewModel.endDate, in: viewModel.startDate..., displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                        }
                        
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            
                            Text("期間: \(viewModel.durationText)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // 반복 정보 표시 (편집 불가)
                        if let repeatType = goal.repeatType, repeatType != "none",
                           let repeatCount = goal.repeatCount {
                            HStack {
                                Image(systemName: "repeat")
                                    .foregroundColor(.orange)
                                
                                Text("反復設定: \(repeatCount)\(repeatType == "weekly" ? "週間" : "ヶ月") (編集不可)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                
                                Spacer()
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Spacer()
                    
                    // 저장 버튼
                    Button(action: {
                        viewModel.updateGoal(goalId: goal.id ?? "", groupId: groupId)
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text("目標を更新")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.canUpdateGoal ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!viewModel.canUpdateGoal || viewModel.isLoading)
                }
                .padding()
            }
            .navigationTitle("目標編集")
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
                Text("目標が正常に更新されました！")
            }
        }
        .onAppear {
            viewModel.initialize(with: goal)
        }
    }
}
