//
//  ReportContentView.swift
//  gymroutine-mobile
//
//  Created by AI Assistant on 2025/01/07.
//

import SwiftUI

struct ReportContentView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedReportType: ReportType = .spam
    @State private var additionalDetails: String = ""
    @State private var isSubmitting = false
    
    let contentId: String
    let contentType: String // "workout", "story", "comment", "user"
    let reportedUserId: String
    
    private let userService = UserService.shared
    private let analyticsService = AnalyticsService.shared
    
    enum ReportType: String, CaseIterable {
        case spam = "スパム"
        case harassment = "ハラスメント・いじめ"
        case hateSpeech = "ヘイトスピーチ・差別"
        case violence = "暴力的コンテンツ"
        case inappropriateContent = "不適切なコンテンツ"
        case falseInformation = "虚偽情報"
        case copyrightViolation = "著作権侵害"
        case other = "その他"
        
        var description: String {
            switch self {
            case .spam:
                return "繰り返し投稿される迷惑なコンテンツ"
            case .harassment:
                return "特定の人物への嫌がらせやいじめ行為"
            case .hateSpeech:
                return "差別的発言や特定のグループへの攻撃"
            case .violence:
                return "暴力を助長する内容や脅迫"
            case .inappropriateContent:
                return "性的または不適切な内容"
            case .falseInformation:
                return "意図的な嘘や誤解を招く情報"
            case .copyrightViolation:
                return "著作権で保護された素材の無断使用"
            case .other:
                return "上記以外の問題"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        reportTypeSection
                        detailsSection
                    }
                    .padding()
                }
                
                submitButton
            }
            .navigationTitle("コンテンツを報告")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            analyticsService.logScreenView(screenName: "ReportContent")
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("問題のあるコンテンツを報告")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("コミュニティガイドラインに違反するコンテンツを発見した場合は、報告してください。報告されたコンテンツは24時間以内にレビューされます。")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    private var reportTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("報告の種類")
                .font(.headline)
            
            ForEach(ReportType.allCases, id: \.self) { reportType in
                Button(action: {
                    selectedReportType = reportType
                }) {
                    HStack {
                        Image(systemName: selectedReportType == reportType ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedReportType == reportType ? .blue : .gray)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(reportType.rawValue)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(reportType.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedReportType == reportType ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("追加の詳細（任意）")
                .font(.headline)
            
            TextEditor(text: $additionalDetails)
                .frame(minHeight: 100)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            Text("問題の詳細をご記入ください。より詳しい情報により、適切な対応を取ることができます。")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var submitButton: some View {
        VStack(spacing: 16) {
            Button(action: submitReport) {
                if isSubmitting {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("送信中...")
                    }
                } else {
                    Text("報告を送信")
                        .font(.headline)
                }
            }
            .disabled(isSubmitting)
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal)
            
            Text("報告は匿名で送信されます")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 20)
        .background(Color(UIColor.systemBackground))
    }
    
    private func submitReport() {
        guard !isSubmitting else { return }
        
        isSubmitting = true
        
        Task {
            do {
                try await userService.reportContent(
                    contentId: contentId,
                    contentType: contentType,
                    reportedUserId: reportedUserId,
                    reportType: selectedReportType.rawValue,
                    details: additionalDetails.isEmpty ? nil : additionalDetails
                )
                
                // Log report submission
                analyticsService.logContentReported(
                    contentId: contentId,
                    contentType: contentType,
                    reportType: selectedReportType.rawValue
                )
                
                await MainActor.run {
                    UIApplication.showBanner(type: .success, message: "報告が送信されました。ご協力ありがとうございます。")
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    UIApplication.showBanner(type: .error, message: "報告の送信に失敗しました。再度お試しください。")
                }
            }
            
            await MainActor.run {
                isSubmitting = false
            }
        }
    }
}

#Preview {
    ReportContentView(
        contentId: "test-content-id",
        contentType: "workout",
        reportedUserId: "test-user-id"
    )
} 