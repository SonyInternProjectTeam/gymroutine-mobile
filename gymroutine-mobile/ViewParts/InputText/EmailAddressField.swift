//
//  EmailAddressField.swift
//  gymroutine-mobile
//
//  Created by 森祐樹 on 2024/11/23.
//

import SwiftUI

struct EmailAddressField: View {

    @Binding var text: String
    
    var body: some View {
        TextField("", text: $text)
            .keyboardType(.emailAddress)
            .submitLabel(.done)
            .disableAutocorrection(true)    // typo警告を非表示
            .textInputAutocapitalization(.never)
            .fieldBackground()
    }
}

#Preview {
    @Previewable @State var text = ""
    EmailAddressField(text: $text)
}
