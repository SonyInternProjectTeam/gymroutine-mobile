//
//  WorkoutCell.swift
//  gymroutine-mobile
//
//  Created by SATTSAT on 2025/01/09
//
//

import SwiftUI

struct WorkoutCell: View {
    let workoutName: String
    let count: Int
    
    var body: some View {
        HStack {
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
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ScrollView {
        WorkoutCell(workoutName: "一軍ワークアウト", count: 6)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.secondary)
}

