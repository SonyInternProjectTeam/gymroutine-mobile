//
//  TermsOfServiceView.swift
//  gymroutine-mobile
//
//  Created by AI Assistant on 2025/01/07.
//

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var hasScrolledToBottom = false
    @State private var agreedToTerms = false
    
    let onAgree: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("利用規約&プライバシーポリシー")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.top)
                            
                            termsContent
                            
                            Text("コミュニティガイドライン")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.top)
                            
                            communityGuidelinesContent
                            
                            Text("プライバシーポリシー")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.top)
                            
                            privacyPolicyContent
                            
                            Spacer()
                                .id("bottom")
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                    .onAppear {
                        // Scroll to bottom automatically to ensure user sees full content
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.easeInOut(duration: 1.0)) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: hasScrolledToBottom) { _, _ in
                        // Enable agreement checkbox when user has scrolled to bottom
                    }
                }
                
                // Agreement section
                VStack(spacing: 16) {
                    HStack {
                        Button(action: {
                            agreedToTerms.toggle()
                        }) {
                            Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                .foregroundColor(agreedToTerms ? .blue : .gray)
                                .font(.title2)
                        }
                        
                        Text("上記の利用規約、コミュニティガイドライン、プライバシーポリシーに同意します")
                            .font(.footnote)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    Button(action: {
                        onAgree()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("同意して続行")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(agreedToTerms ? Color.blue : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(!agreedToTerms)
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
                .background(Color(UIColor.systemBackground))
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private var termsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("第1条（目的）")
                .font(.headline)
            Text("本規約はユーザーが提供する運動記録・分析・共有などのサービスを利用するにあたり、必要な条件および手続きを定め、権利と義務を明確にすることを目的とします。")
                .font(.body)
            
            Text("第2条（サービス内容）")
                .font(.headline)
            Text("• ユーザーの運動記録の登録および管理\n• 運動結果の分析および統計（運動部位別の分布、体重変化、運動遵守率、お気に入り運動、1回最大重量など）\n• フォロワーおよびフォロー中ユーザー間の運動データ比較\n• 運動ストーリーの共有")
                .font(.body)
            
            Text("第3条（ユーザーの義務）")
                .font(.headline)
            Text("ユーザーは本サービスを利用する際に以下を遵守する必要があります。\n\n• 他人の情報を無断で使用または共有しないこと。\n• 自身の運動情報およびデータを正確に入力・管理すること。")
                .font(.body)
            
            Text("第4条（サービスの変更および中断）")
                .font(.headline)
            Text("運営者はサービスの内容や提供方法を技術的必要性に応じて変更または中断することがあり、その場合は事前に通知します。")
                .font(.body)
            
            Text("第5条（責任の限定）")
                .font(.headline)
            Text("運営者はユーザーが入力した情報の誤りや不正確さにより発生した損害について一切の責任を負いません。")
                .font(.body)
        }
    }
    
    private var communityGuidelinesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("不適切なコンテンツに対するゼロトレランス")
                .font(.headline)
                .foregroundColor(.red)
            
            Text("当アプリは、以下の内容に対して一切の寛容を示しません：")
                .font(.body)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• ヘイトスピーチや差別的表現")
                Text("• ハラスメントやいじめ")
                Text("• 暴力的または脅迫的な内容")
                Text("• 性的に不適切な内容")
                Text("• スパムや迷惑行為")
                Text("• 虚偽情報の拡散")
                Text("• 著作権侵害")
            }
            .font(.body)
            .padding(.leading, 16)
            
            Text("報告とモデレーション")
                .font(.headline)
            Text("• 不適切なコンテンツを発見した場合は、すぐに報告してください\n• 報告されたコンテンツは24時間以内にレビューされます\n• 違反が確認された場合、警告またはアカウント停止の措置を取ります")
                .font(.body)
            
            Text("コミュニティへの貢献")
                .font(.headline)
            Text("• 建設的で支援的なコミュニティの構築にご協力ください\n• 他のユーザーのフィットネス目標を尊重し、励ましてください\n• 安全で包括的な環境の維持にご協力ください")
                .font(.body)
        }
    }
    
    private var privacyPolicyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("収集する個人情報")
                .font(.headline)
            Text("• 基本情報：ニックネーム、性別、生年月日、プロフィール画像、ユーザーID\n• 運動情報：体重記録、運動記録（運動名、回数、重量）、運動頻度、遵守率など\n• ユーザー間の関係情報：フォローおよびフォロワー情報")
                .font(.body)
            
            Text("個人情報の収集および利用目的")
                .font(.headline)
            Text("• ユーザー個別に最適化された運動分析および推薦の提供\n• 運動データに基づく統計分析\n• ユーザー間の運動データ比較および共有サービスの提供")
                .font(.body)
            
            Text("個人情報の保管および利用期間")
                .font(.headline)
            Text("ユーザーの個人情報はサービス利用期間中のみ保存され、サービス退会または個人情報提供の同意撤回時に即時破棄されます。")
                .font(.body)
            
            Text("第三者への情報提供")
                .font(.headline)
            Text("ユーザーの同意なしに第三者に個人情報が提供されることはありません。")
                .font(.body)
            
            Text("ユーザーの権利")
                .font(.headline)
            Text("• ユーザーはいつでも自分の個人情報を閲覧・修正・削除要求できます。\n• 個人情報処理への同意を撤回することができます。")
                .font(.body)
            
            Text("クッキーおよびGoogleアナリティクスの利用")
                .font(.headline)
            Text("本サービスはユーザーの利用パターン分析およびサービス品質向上のためGoogleアナリティクスを使用します。Googleアナリティクスはクッキーを利用して匿名でデータを収集します。ユーザーはブラウザの設定を通じてクッキーの利用を制限または拒否できます。詳しくは[Googleのデータ利用方法](https://policies.google.com/technologies/partner-sites)および[Googleアナリティクスのプライバシーポリシー](https://support.google.com/analytics/answer/7318509?hl=ja)をご確認ください。ただし、クッキーを拒否した場合、一部のサービスが正常に機能しない可能性があります。")
                .font(.body)
            
            Text("作成日：2025-05-08")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
    }
}

#Preview {
    TermsOfServiceView(onAgree: {})
} 