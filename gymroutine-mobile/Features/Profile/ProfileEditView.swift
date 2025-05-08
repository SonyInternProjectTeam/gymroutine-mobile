//
//  ProfileEditView.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2025/04/15.
//

import SwiftUI

struct ProfileEditView: View {
    let user: User
    @StateObject var viewModel: ProfileEditViewModel
    @State private var name: String
    @State private var visibility: Int
    private let analyticsService = AnalyticsService.shared
    
    //アラートに関する変数
    @State private var showAlert = false
    @State private var alertType: AlertType?
    @Environment(\.presentationMode) var presentationMode
    
    enum AlertType: Identifiable {
        case confirmUpdate, noChanges, confirmLogout, confirmDeleteAccount, updateSuccess, updateFailure
        var id: Int {hashValue}
    }
    
    let visibilityOptions = [
        1: "全体公開",
        2: "友人のみ",
        3: "非公開"
    ]
    
    init (user: User, router: Router) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: .init(user: user, router: router))
        self._name = State(initialValue: user.name)
        self._visibility = State(initialValue: user.visibility)
    }
    
    var body: some View {
        Form {
            Section(header: Text("ユーザー設定").fontWeight(.semibold)) {
                VStack(alignment: .leading) {
                    Label("ユーザー名", systemImage: "pencil")
                        .font(.headline)
                    
                    
                    TextField("ユーザー名を入力", text: $name)
                        .fontWeight(.semibold)
                        .padding(12)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading) {
                    Label("公開設定", systemImage: "person.3")
                        .font(.headline)
                    
                    Picker("公開範囲", selection: $visibility) {
                        ForEach(visibilityOptions.keys.sorted(), id: \.self) { key in
                            Text(visibilityOptions[key]!).tag(key)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Button {
                    alertType = .confirmUpdate
                } label: {
                    Text("変更を保存")
                        .font(.headline)
                }
                .disabled(name == user.name && visibility == user.visibility)
                .buttonStyle(CapsuleButtonStyle(color: .main))
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom)
                .listRowSeparator(.hidden)
            }
            
            // Account management section
            Section(header: Text("アカウント管理").fontWeight(.semibold)) {
                Button(action: {
                    alertType = .confirmLogout
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("ログアウト")
                    }
                }
                .foregroundColor(.blue)
                
                Button(action: {
                    alertType = .confirmDeleteAccount
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.minus")
                        Text("アカウントを削除")
                    }
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("ユーザー設定")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.immediately)
        .onAppear(perform: viewModel.refreshUserData)
        .onChange(of: viewModel.showMessage) { _, newValue in
            if newValue {
                // Show success or failure message
                if viewModel.updateSuccess {
                    alertType = .updateSuccess
                } else {
                    alertType = .updateFailure
                }
                viewModel.showMessage = false
            }
        }
        .alert(item: $alertType) { type in
            switch type {
            case .confirmUpdate:
                return Alert(
                    title: Text("確認"),
                    message: Text("変更してよろしいですか？"),
                    primaryButton: .default(Text("はい"), action: {
                        viewModel.updateUser(newVisibility: visibility, newName: name)
                    }),
                    secondaryButton: .cancel(Text("いいえ"))
                )
            case .noChanges:
                return Alert(
                    title: Text("お知らせ"),
                    message: Text("変更点がありません"),
                    dismissButton: .default(Text("OK"))
                )
            case .confirmLogout:
                return Alert(
                    title: Text("ログアウト確認"),
                    message: Text("本当にログアウトしますか？"),
                    primaryButton: .destructive(Text("ログアウト"), action: {
                        viewModel.logout()
                    }),
                    secondaryButton: .cancel(Text("キャンセル"))
                )
            case .confirmDeleteAccount:
                return Alert(
                    title: Text("アカウント削除確認"),
                    message: Text("この操作は取り消しできません。\n本当にアカウントを削除しますか？"),
                    primaryButton: .destructive(Text("削除する"), action: {
                        viewModel.deleteAccount()
                    }),
                    secondaryButton: .cancel(Text("キャンセル"))
                )
            case .updateSuccess:
                return Alert(
                    title: Text("成功"),
                    message: Text("プロフィールが更新されました"),
                    dismissButton: .default(Text("OK")) {
                        // Dismiss the view after successful update
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            case .updateFailure:
                return Alert(
                    title: Text("エラー"),
                    message: Text(viewModel.errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

#Preview {
    ProfileEditView(user:User(uid: "5CKiKZmOzlhkEECu4VBDZGltkrn2",
                              email: "wkk03240324@gmail.com",
                              name: "Kakeru Koizumi",
                              profilePhoto: "",
                              visibility: 2,
                              isActive: false,
                              birthday: Date(timeIntervalSince1970: 1017570720),
                              gender: "男",
                              createdAt: Date(timeIntervalSince1970: 1735656838)
                             ), router: Router())
}
