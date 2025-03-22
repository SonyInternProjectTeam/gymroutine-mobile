//
//  BannerView.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2025/03/20
//  
//

import SwiftUI

enum BannerType {
    case success
    case error
    case notice
    
    var color: Color {
        switch self {
        case .success:
            return .green
        case .error:
            return .red
        case .notice:
            return .main
        }
    }
    
    var icon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .notice:
            return "info.circle.fill"
        }
    }
}

struct BannerView: View {
    
    let type: BannerType
    let message: String
    
    @State private var isVisible: Bool = false
    private let generator = UINotificationFeedbackGenerator()
    
    var body: some View {
        VStack {
            if isVisible {
                HStack(spacing: 16) {
                    Image(systemName: type.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                    
                    Text(message)
                        .hAlign(.leading)
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.vertical, 12)
                .padding(.horizontal)
                .hAlign(.leading)
                .background(type.color)
                .clipShape(Capsule())
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: isVisible)
            }
            
            Spacer()
        }
        .padding(.top)
        .onAppear {
            vibration()
            withAnimation {
                isVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    isVisible = false
                }
            }
        }
    }
    
    func vibration() {
        switch self.type {
        case .success:
            self.generator.notificationOccurred(.success)
        case .error:
            self.generator.notificationOccurred(.error)
        case .notice:
            self.generator.notificationOccurred(.warning)
        }
    }
}

#Preview {
    BannerView(type: .notice, message: "サンプルバナーです")
}
