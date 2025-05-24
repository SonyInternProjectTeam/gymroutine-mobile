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
    @State private var birthday: Date
    @State private var hasBirthday: Bool
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
    
    var isUnchanged: Bool {
        let nameUnchanged = name == user.name
        let visibilityUnchanged = visibility == user.visibility
        
        // Check birthday changes more carefully
        let birthdayUnchanged: Bool
        if hasBirthday {
            // User wants to have a birthday
            if let userBirthday = user.birthday {
                // User currently has a birthday - check if it's the same date
                birthdayUnchanged = Calendar.current.isDate(birthday, inSameDayAs: userBirthday)
            } else {
                // User currently doesn't have a birthday but wants to set one - this is a change
                birthdayUnchanged = false
            }
        } else {
            // User doesn't want to have a birthday
            birthdayUnchanged = user.birthday == nil
        }
        
        return nameUnchanged && visibilityUnchanged && birthdayUnchanged
    }
    
    init (user: User, router: Router) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: .init(user: user, router: router))
        self._name = State(initialValue: user.name)
        self._visibility = State(initialValue: user.visibility)
        self._birthday = State(initialValue: user.birthday ?? Date())
        self._hasBirthday = State(initialValue: user.birthday != nil)
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
                
                VStack(alignment: .leading) {
                    Label("誕生日", systemImage: "calendar")
                        .font(.headline)
                    
                    Toggle("誕生日を設定", isOn: $hasBirthday)
                        .font(.subheadline)
                        .padding(.bottom, 8)
                        .onChange(of: hasBirthday) { oldValue, newValue in
                            if !newValue && user.birthday != nil {
                                // User turned off birthday toggle and currently has a birthday set
                                // This will be handled in the save action
                                print("誕生日の削除が予定されています")
                            }
                        }
                    
                    if hasBirthday {
                        DatePicker(
                            "誕生日を選択",
                            selection: $birthday,
                            displayedComponents: .date
                        )
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                    } else if user.birthday != nil {
                        Text("誕生日が削除されます")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal)
                    }
                }
                
                Button {
                    alertType = .confirmUpdate
                } label: {
                    Text("変更を保存")
                        .font(.headline)
                }
                .disabled(isUnchanged)
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
        .onAppear {
            viewModel.refreshUserData()
            
            // Log screen view
            analyticsService.logScreenView(screenName: "ProfileEdit")
        }
        .onChange(of: viewModel.user) { _, newUser in
            if let user = newUser {
                name = user.name
                visibility = user.visibility
                birthday = user.birthday ?? Date()
                hasBirthday = user.birthday != nil
            }
        }
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
                let shouldDeleteBirthday = !hasBirthday && user.birthday != nil
                let message = shouldDeleteBirthday ? 
                    "変更を保存すると誕生日が削除されます。よろしいですか？" : 
                    "変更してよろしいですか？"
                
                return Alert(
                    title: Text("確認"),
                    message: Text(message),
                    primaryButton: .default(Text("はい"), action: {
                        let birthdayToUpdate = hasBirthday ? birthday : nil
                        
                        viewModel.updateUser(
                            newVisibility: visibility,
                            newName: name,
                            newBirthday: birthdayToUpdate,
                            shouldDeleteBirthday: shouldDeleteBirthday
                        )
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
