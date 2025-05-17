//
//  WorkoutTemplateCell.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/05/12.
//

import SwiftUI

struct WorkoutTemplateCell: View {
    let template: WorkoutTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Template header
            HStack {
                Text(template.name)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if template.isPremium {
                    Label("Premium", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            // Schedule days & duration
            HStack {
                Label(template.scheduledDays.joined(separator: ", "), systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label(template.duration, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Level
            Label(template.level, systemImage: "chart.bar")
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
            
            // Exercise count
            Text("\(template.exercises.count) Exercises")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Notes (if available)
            if let notes = template.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
