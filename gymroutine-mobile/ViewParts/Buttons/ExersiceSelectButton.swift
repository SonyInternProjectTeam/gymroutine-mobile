//
//  ExersiceSelectButton.swift
//  gymroutine-mobile
//
//  Created by 堀壮吾 on 2024/11/29.
//

import SwiftUI

struct ExersiceSelectButton: View {
    var name: String = ""
    var option: String = ""
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Image(.welcomeLogo)
                .resizable()
                .scaledToFit()
                .frame(width: 115,height: 115)
            Text(name)
                .font(.headline)
                .foregroundColor(.black)
            
            Divider()
            Text(option)
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


#Preview {
    HStack(spacing: 10) {
        ExersiceSelectButton(name:"ショルダープレス",option: "腕")
        ExersiceSelectButton(name:"腹筋",option: "腹筋")
    }
    .padding()
    .background(.gray.opacity(0.2))
    
}
