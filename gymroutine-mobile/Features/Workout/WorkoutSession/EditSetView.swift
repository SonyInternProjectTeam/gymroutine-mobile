//
//  EditSetView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/05/21.
//

import SwiftUI

struct EditSetView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var weightText: String
    @State private var repsText: String
    private let analyticsService = AnalyticsService.shared
    private let textFieldSize = UIScreen.main.bounds.width * 0.5
    
    var onSave: (Double, Int) -> Void
    
    init(weight: Double, reps: Int, onSave: @escaping (Double, Int) -> Void) {
        self._weightText = State(initialValue: String(format: "%.1f", weight))
        self._repsText = State(initialValue: String(reps))
        self.onSave = onSave
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("セット編集")
                .font(.headline)
                .padding(.top)
            
            CustomDivider()
            
            VStack(spacing: 24) {
                HStack(spacing: 0) {
                    Text("重さ(kg)")
                        .font(.headline)
                    Spacer()
                    TextField("0.0", text: $weightText)
                        .keyboardType(.decimalPad)
                        .font(.headline)
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        .background(Color(UIColor.systemGray6))
                        .multilineTextAlignment(.leading)
                        .cornerRadius(8)
                        .frame(width: textFieldSize)
                }
                
                HStack(spacing: 0) {
                    Text("レップ数(回)")
                        .font(.headline)
                    Spacer()
                    TextField("1", text: $repsText)
                        .keyboardType(.numberPad)
                        .font(.headline)
                        .padding(.vertical,10)
                        .padding(.horizontal)
                        .background(Color(UIColor.systemGray6))
                        .multilineTextAlignment(.leading)
                        .cornerRadius(8)
                        .frame(width: textFieldSize)
                }
            }
            .vAlign(.center)
        }
        .padding(24)
        .vAlign(.top)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button("キャンセル") {
                    dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("保存") {
                    onClickedSaveButton()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
        }
        .onAppear {
            // Log screen view
            analyticsService.logScreenView(screenName: "EditSet")
        }
    }
    
    private func onClickedSaveButton() {
        // 空欄ならデフォルトを補完
        let weightValue = weightText.isEmpty ? 0.0 : Double(weightText)
        let repsValue = repsText.isEmpty ? 1 : Int(repsText)

        // フォーマットチェック
        guard let weight = weightValue, let reps = repsValue else {
            UIApplication.showBanner(type: .error, message: "数値の形式が正しくありません")
            return
        }

        // 範囲チェック
        if !(0.0...300.0).contains(weight) {
            UIApplication.showBanner(type: .error, message: "重さは0〜300kgの間で入力してください")
            return
        }

        if !(1...100).contains(reps) {
            UIApplication.showBanner(type: .error, message: "レップ数は1〜100回の間で入力してください")
            return
        }

        onSave(weight, reps)
        dismiss()
    }
}

#Preview {
    EditSetView(weight: 50.0, reps: 10) { _, _ in }
} 
