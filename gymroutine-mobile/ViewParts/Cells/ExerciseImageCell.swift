//
//  ExerciseImageCell.swift
//  gymroutine-mobile
//
//  Created by 森祐樹 on 2025/04/02.
//

import SwiftUI

struct ExerciseImageCell: View {

    let imageName: String?

    var body: some View {
        Group {
            if let imageName = imageName, let uiImage = UIImage(named: imageName)  {
                Image(uiImage: uiImage)
                    .resizable()
            } else {
                Image(systemName: "nosign")
                    .resizable()
                    .foregroundStyle(.gray)
                    .padding(16)
            }
        }
        .scaledToFill()
        .cornerRadius(8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.gray, lineWidth: 1)
        }
    }
}

#Preview {
    ExerciseImageCell(imageName: "")
        .frame(width: 48, height: 48)
}
