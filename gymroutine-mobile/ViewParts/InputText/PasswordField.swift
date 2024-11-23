//
//  PasswordField.swift
//  gymroutine-mobile
//
//  Created by 森祐樹 on 2024/11/23.
//

import SwiftUI
import UIKit

struct PasswordField: View {

    @State var isSecured: Bool = true
    @Binding var text: String

    var body: some View {
        HStack(spacing: 4) {
            UIKitPasswordField(text: $text, isSecured: $isSecured)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: {
                isSecured.toggle()
            }) {
                Image(systemName: isSecured ? "eye.slash" : "eye")
                    .accentColor(.gray)
            }
        }
        .fieldBackground()
    }
}

#Preview {
    @Previewable @State var text = ""
    PasswordField(text: $text)
}

struct UIKitPasswordField: UIViewRepresentable {

    @Binding var text: String
    @Binding var isSecured: Bool

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.isSecureTextEntry = isSecured
        textField.placeholder = ""
        textField.backgroundColor = UIColor.clear
        textField.delegate = context.coordinator
        textField.returnKeyType = .done
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textChanged), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        uiView.isSecureTextEntry = isSecured
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: UIKitPasswordField

        init(_ parent: UIKitPasswordField) {
            self.parent = parent
        }

        @objc func textChanged(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder() // キーボードを閉じる
            return true
        }
    }
}
