//
//  WorkoutCell.swift
//  gymroutine-mobile
//
//  Created by SATTSAT on 2025/01/09
//
//

import SwiftUI

struct WorkoutCell: View {
    
    //workoutモデルがないため仮の変数を宣言
    let workoutName: String = "一軍ワークアウト"
    let count: Int = 6
    let profileImageUrl: String? = nil
    var body: some View {
        HStack {
            Group {
                if let profileImageUrl {
                    //URLが存在したら、URLから画像を取得するKingFisherパッケージなどを導入してここに追加
                    Text("URLから画像処理")
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.main)
                        .frame(width: 48, height: 48)
                }
            }
            
            VStack(alignment: .leading) {
                Text("\(count)種目")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                
                Text(workoutName)
                    .font(.headline)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("〉")
                .foregroundStyle(.secondary)
                .bold()
        }
        .padding(8)
        .background(.background)
        .clipShape(.rect(cornerRadius: 8))
    }
}

#Preview {
    ScrollView {
        WorkoutCell()
        WorkoutCell()
        WorkoutCell()
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.secondary)
}
