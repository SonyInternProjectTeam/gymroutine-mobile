//
//  DateTF.swift
//  gymroutine-mobile
//
//  Created by 森祐樹 on 2025/01/01.
//

import SwiftUI

/// キーボードの代わりにDatePickerを表示させ、日付を入力するカスタムビュー
/// 参考: https://www.youtube.com/watch?v=wnrtI4qXghc
struct DateInputField: View {

    var components: DatePickerComponents = .date
    @Binding var date: Date
    var formattedString: (Date) -> String

    @State private var viewId: String = UUID().uuidString
    @FocusState private var isActive

    var body: some View {
        TextField(viewId, text: .constant(formattedString(date)))
            .overlay {
                AddInputViewToTextField(id: viewId) {
                    DatePicker("", selection: $date, in: ...Date(), displayedComponents: components)
                        .labelsHidden()
                        .datePickerStyle(.wheel)
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                        .padding(.vertical, 32)
                }
                .onTapGesture {
                    isActive = true
                }
            }
            .focused($isActive)
            .toolbar {
                if isActive {
                    ToolbarItem(placement: .keyboard) {
                        Button("完了") {
                            isActive = false
                        }
                        .tint(.primary)
                        .hAlign(.trailing)
                    }
                }
            }
    }
}

fileprivate struct AddInputViewToTextField<Content: View>: UIViewRepresentable {
    var id: String
    @ViewBuilder var content: Content

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        DispatchQueue.main.async {
            if let window = view.window, let textField = window.allSubViews(type: UITextField.self).first(where: {$0.placeholder == id}) {
                textField.tintColor = .clear
                let hostView = UIHostingController(rootView: content).view!
                hostView.backgroundColor = .clear
                hostView.frame.size = hostView.intrinsicContentSize

                textField.inputView = hostView
                textField.reloadInputViews()
            }
        }

        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) { }
}

fileprivate extension UIView {
    func allSubViews<T: UIView>(type: T.Type) -> [T] {
        var resultViews = subviews.compactMap({ $0 as? T })

        for view in subviews {
            resultViews.append(contentsOf: view.allSubViews(type: type))
        }

        return resultViews
    }
}

#Preview {
    @Previewable @State var date = Date()
    DateInputField(date: $date) { date in
        return date.formatted()
    }
}
