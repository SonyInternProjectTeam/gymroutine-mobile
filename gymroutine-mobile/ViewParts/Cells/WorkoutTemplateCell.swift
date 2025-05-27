//
//  WorkoutTemplateCell.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/05/12.
//

import SwiftUI

struct WorkoutTemplateCell: View {
    let template: WorkoutTemplate
    var localizedScheduledDays: String {
        let dayMap: [String: String] = [
            "Sunday": "日",
            "Monday": "月",
            "Tuesday": "火",
            "Wednesday": "水",
            "Thursday": "木",
            "Friday": "金",
            "Saturday": "土"
        ]
        
        return template.scheduledDays
            .compactMap { dayMap[$0] }
            .joined(separator: ", ")
    }
    private let luxuryColor = Color(red: 0.8, green: 0.7, blue: 0)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            HStack(spacing: 16) {
                if let icon = UIApplication.shared.icon {
                    Image(uiImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48)
                        .clipShape(.rect(cornerRadius: 6))
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("\(template.exercises.count) 種目")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.semibold)
                        
                        if template.isPremium {
                            Text("プレミアム")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 12)
                                .background(luxuryColor)
                                .clipShape(.rect(cornerRadius: 6))
                        }
                    }
                    
                    Text(template.name)
                        .font(.headline)
                }
                
                Spacer()
                
                Text("〉")
                    .font(.title.bold())
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 0) {
                itemCell(
                    title: "曜日",
                    systemImage: "calendar",
                    value: localizedScheduledDays
                )
                itemCell(
                    title: "期間",
                    systemImage: "clock",
                    value: template.duration
                )
                itemCell(
                    title: "難易度",
                    systemImage: "chart.bar",
                    value: template.level
                )
            }
            .padding()
            .background(.main.opacity(0.1))
            .cornerRadius(6)
            
            CustomDivider()
            
            if let notes = template.notes, !notes.isEmpty {
                Text(notes)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    @ViewBuilder
    private func itemCell(title: String, systemImage: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption)
            
            Text(value)
                .font(.headline)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    VStack(spacing: 16) {
        WorkoutTemplateCell(template: WorkoutTemplate.mock)
        WorkoutTemplateCell(template: WorkoutTemplate.premiumMock)
    }
    .padding()
}
