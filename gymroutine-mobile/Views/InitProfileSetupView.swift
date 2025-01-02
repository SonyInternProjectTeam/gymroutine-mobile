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
        VStack(spacing: 36) {
            CustomTabBar(items: viewModel.setupSteps, currentItem: viewModel.currentStep)
                .padding(.horizontal, 16)

            Group {
                switch viewModel.currentStep {
                case .nickname:
                    nicknameView
                case .gender:
                    genderView
                case .birthday:
                    birthdayView
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            actionButton
        }
        .padding(.vertical, 24)
    }
}

// MARK: - Views
extension InitProfileSetupView {
    private var nicknameView: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("ニックネームを入力してください")
                .font(.title)
                .bold()

            VStack(alignment: .leading, spacing: 12) {
                TextField("入力してください", text: $viewModel.name)
                    .fieldBackground()
                    .submitLabel(.done)

                Text("後から変更できます")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                    .padding(.leading, 4)
            }
        }
    }

    private var genderView: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("性別を教えてください")
                .font(.title)
                .bold()

            VStack(spacing: 16) {
                ForEach(InitProfileSetupViewModel.Gender.allCases, id: \.self) { gender in
                    Button {
                        viewModel.selectGender(gender)
                    } label: {
                        Text(gender.displeyText)
                    }
                    .buttonStyle(SelectableButtonStyle(isSelected: viewModel.isSelectedGender(gender)))
                }
            }
        }
        .sensoryFeedback(.selection, trigger: viewModel.gender)
    }

    private var birthdayView: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("生年月日を教えてください")
                .font(.title)
                .bold()

            DateInputField(date: $viewModel.birthday) { date in
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "ja_JP") // 日本語ロケール
                formatter.dateStyle = .long
                return formatter.string(from: date)
            }
        }
    }

    private var actionButton: some View {
        Group {
            if let nextStep = viewModel.currentStep.nextStep {
                Button {
                    viewModel.toNextStep(nextStep)
                } label: {
                    Text("次へ")
                }
            } else {
                Button {
                    viewModel.saveAdditionalInfo()
                } label: {
                    Text("登録する")
                }
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(viewModel.isDisabledActionButton())
    }
}

#Preview {
    InitProfileSetupView(
        viewModel: InitProfileSetupViewModel(
            router: Router())
    )
}
