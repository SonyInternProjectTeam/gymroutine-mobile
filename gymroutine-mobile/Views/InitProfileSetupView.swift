//
//  InitProfileSetupView.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2024/12/26
//  
//

import SwiftUI

struct InitProfileSetupView: View {
    
    @ObservedObject var viewModel: InitProfileSetupViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("追加情報を入力してください")
                    .font(.title)
                    .padding(.bottom, 16)

                TextField("名前", text: $viewModel.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                TextField("年齢", value: $viewModel.age, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                TextField("性別 (例: 男性/女性)", text: $viewModel.gender)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                DatePicker("生年月日", selection: $viewModel.birthday, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())

                Spacer()

                Button(action: {
                    viewModel.saveAdditionalInfo()
                }) {
                    Text("登録完了")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}

#Preview {
    InitProfileSetupView(
        viewModel: InitProfileSetupViewModel(
            router: Router())
    )
}
