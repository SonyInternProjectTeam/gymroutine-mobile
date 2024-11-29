//
//  SuccessView.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2024/11/29.
//

import Foundation
import SwiftUI

struct SuccessView: View {
    var body: some View {
        VStack {
            Text("Login Successful!")
                .font(.largeTitle)
                .padding()

            Text("You have successfully logged in!")
                .font(.title)
                .padding()

            Spacer()
        }
        .navigationTitle("Success Page")
        .navigationBarBackButtonHidden(true)  // hide back arrow
    }
}

#Preview {
    SuccessView()
}
