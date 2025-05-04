//
//  CustomDivider.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2025/04/27
//  
//

import SwiftUI

struct CustomDivider: View {
    var body: some View {
        Rectangle()
            .fill(LinearGradient(
                gradient: Gradient(colors: [.clear, .primary.opacity(0.3), .clear]),
                startPoint: .leading,
                endPoint: .trailing
            ))
            .frame(height: 2)
    }
}

#Preview {
    VStack(spacing: 24) {
        CustomDivider()
        CustomDivider()
        CustomDivider()
        CustomDivider()
        CustomDivider()
        CustomDivider()
        CustomDivider()
        CustomDivider()
        CustomDivider()
    }
}
