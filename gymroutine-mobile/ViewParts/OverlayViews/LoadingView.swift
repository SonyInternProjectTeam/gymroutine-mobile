//
//  LoadingView.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2025/03/20
//  
//

import SwiftUI

struct LoadingView: View {
    
    @State private var progress: CGFloat = 0.0
    private let size: CGFloat = 70
    
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        Color.black.opacity(0.2)
            .ignoresSafeArea()
            .overlay(alignment: .center) {
                VStack(spacing: 16) {
                    ZStack(alignment: .bottom) {
                        Color.primary
                            
                        
                        Color.main
                            .frame(height: size * progress, alignment: .bottom)
                    }
                    .frame(width: size, height: size)
                    .mask(
                        Image(systemName: "flame.fill")
                            .resizable()
                            .scaledToFit()
                    )
                    
                    if let message {
                        Text(message)
                            .lineLimit(2)
                            .minimumScaleFactor(0.1)
                            .frame(maxWidth: size + 32)
                    }
                }
                .padding(32)
                .background(Color(UIColor.systemGray6))
                .clipShape(.rect(cornerRadius: 8))
                .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1.5)
                .offset(y: -20)
                .onAppear {
                    withAnimation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true)
                    ) {
                        progress = 1.0
                    }
                }
            }
    }
}

#Preview {
    LoadingView(message: "サンプル")
    LoadingView()
}
