//
//  ExerciseSetCell.swift
//  gymroutine-mobile
//  
//  Created by SATTSAT on 2025/05/29
//  
//

import SwiftUI

struct ExerciseSetCell: View {
    
    let index: Int
    let isCurrentIndex: Bool
    let isCompleted: Bool
    let exerciseSet: ExerciseSet
    @State private var dragOffset: CGFloat = .zero
    @State private var isDeletable: Bool = false
    private let width = UIScreen.main.bounds.width
    private let deleteTreshold = UIScreen.main.bounds.width * 0.3
    private let haptic = UIImpactFeedbackGenerator(style: .medium)
    
    var onToggle: () -> Void
    var onDeleted: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("\(index)")
                    .font(.title2.bold())
                    .hAlign(.center)
                
                Text(String(format: "%.1f", exerciseSet.weight))
                    .font(.title2)
                    .hAlign(.center)
                
                Text("\(exerciseSet.reps)")
                    .font(.title2)
                    .hAlign(.center)
                
                Button(action: {
                    onToggle()
                }) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isCompleted ? .green : .secondary)
                        .font(.title2.bold())
                        .hAlign(.center)
                }
                .buttonStyle(.plain)
                
            }
            .overlay(alignment: .leading) {
                if isCurrentIndex {
                    Image(systemName: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding()
            .background(.white)
            .offset(x: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 30, coordinateSpace: .local)
                    .onChanged(handleDragChanged)
                    .onEnded(handleDragEnded)
            )
            .background {
                ZStack(alignment: .trailing) {
                    Color.red
                    
                    Image(systemName: "trash")
                        .scaleEffect(isDeletable ? 1 : 0.6)
                        .font(.title.bold())
                        .foregroundStyle(.white)
                        .frame(width: deleteTreshold, alignment: .center)
                }
            }
            
            Divider()
        }
        .contentShape(.rect)
    }
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        if value.translation.width < 0 {
            dragOffset = value.translation.width
            
            if abs(dragOffset) > deleteTreshold {
                if !isDeletable {
                    haptic.impactOccurred()
                    withAnimation(.interactiveSpring()) {
                        isDeletable = true
                    }
                }
            } else {
                if isDeletable {
                    withAnimation(.interactiveSpring()) {
                        isDeletable = false
                    }
                }
            }
        } else {
            dragOffset = 0
        }
    }

    private func handleDragEnded(_ value: DragGesture.Value) {
        if abs(value.translation.width) > deleteTreshold {
            onDeleted()
        } else {
            withAnimation(.interactiveSpring()) {
                dragOffset = .zero
            }
        }
    }
}

#Preview {
    VStack {
        ForEach(0..<5) {
            ExerciseSetCell(
                index: $0 + 1,
                isCurrentIndex: false,
                isCompleted: false,
                exerciseSet: .init(reps: 10, weight: 60),
                onToggle: {},
                onDeleted: {}
            )
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.mainBackground)
}
