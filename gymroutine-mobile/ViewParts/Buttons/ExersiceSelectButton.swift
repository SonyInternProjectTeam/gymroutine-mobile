//
//  ExersiceSelectButton.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2024/11/29.
//

import SwiftUI

struct ExersiceSelectButton: View {
    var body: some View {
        Button(action: {
            print("tap buton")
        }) {
            VStack(alignment: .center, spacing: 8) {
                Image(.welcomeLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 115,height: 115)
                Text("ショルダープレス")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Divider()
                Text("腕")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .hAlign(.leading)
                
            }
            //            .frame(width: 150,height: 200)
            .padding(12)
            .background(.white)
            .cornerRadius(25)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(.gray, lineWidth:  0)
            )
            
        }
    }
}


#Preview {
    HStack(spacing: 10) {
        ExersiceSelectButton()
        ExersiceSelectButton()
    }
    .padding()
    .background(.gray.opacity(0.2))
    
}
