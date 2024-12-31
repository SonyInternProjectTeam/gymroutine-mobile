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
    @State private var currentStep: SetupStep = .nickname
    
    var body: some View {
        VStack(spacing: 36) {
            TabBarView(currentStep: currentStep)
                .padding(.horizontal, 16)

            Group {
                switch currentStep {
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

// MARK: - Setup Step
extension InitProfileSetupView {
    enum SetupStep: CaseIterable {
        case nickname
        case gender
        case birthday

        var nextStep: SetupStep? {
            switch self {
            case .nickname:
                return    .gender
            case .gender:
                return   .birthday
            case .birthday:
                return nil
            }
        }
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

    // TODO: OTP風の入力にする
    private var birthdayView: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("生年月日を教えてください")
                .font(.title)
                .bold()

            DatePicker("", selection: $viewModel.birthday, displayedComponents: .date)
        }
    }

    // TODO: disable対応
    private var actionButton: some View {
        Group {
            if let nextStep = currentStep.nextStep {
                Button {
                    self.currentStep = nextStep
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
    }
}

// MARK: - Tab Bar
extension InitProfileSetupView {
    struct TabBarView: View {

        let currentStep: SetupStep
        @Namespace var namespace

        var body: some View {
            HStack(alignment: .bottom) {
                ForEach(SetupStep.allCases, id: \.self) { step in
                    TabBarItem(step: step,
                               currentStep: currentStep,
                               namespace: namespace)
                }
            }
        }
    }

    struct TabBarItem: View {

        let step: SetupStep
        let currentStep: SetupStep
        let namespace: Namespace.ID

        var body: some View {
            ZStack {
                Color(.systemGray4)

                if currentStep == step {
                    Color.main
                        .matchedGeometryEffect(id: "line",
                                               in: namespace,
                                               properties: .frame)
                }
            }
            .frame(height: 2)
            .animation(.spring(), value: currentStep)
        }
    }
}


#Preview {
    InitProfileSetupView(
        viewModel: InitProfileSetupViewModel(
            router: Router())
    )
}
