//
//  WorkoutTemplateModel.swift
//  gymroutine-mobile
//
//  Created by 조성화 on 2025/05/12.
//

import Foundation
import FirebaseFirestore

struct WorkoutTemplate: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let scheduledDays: [String]
    let exercises: [WorkoutExercise]
    let notes: String?
    let isPremium: Bool
    let level: String
    let duration: String
    let templateId: String?
    let isRoutine: Bool?
    let createdAt: Date?
    
    // Firebase에서 문서 디코딩을 위한 CodingKeys
    private enum CodingKeys: String, CodingKey {
        case id, name, scheduledDays, exercises, notes, Notes, isPremium, level, duration, templateId, isRoutine, createdAt
    }
    
    // 커스텀 디코더 메서드
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // ID는 Firestore의 DocumentID 어노테이션이 처리
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        scheduledDays = try container.decode([String].self, forKey: .scheduledDays)
        exercises = try container.decode([WorkoutExercise].self, forKey: .exercises)
        
        // notes는 대소문자 구분이 있을 수 있음 (notes 또는 Notes)
        if let lowercaseNotes = try? container.decodeIfPresent(String.self, forKey: .notes) {
            notes = lowercaseNotes
        } else {
            notes = try container.decodeIfPresent(String.self, forKey: .Notes)
        }
        
        isPremium = try container.decode(Bool.self, forKey: .isPremium)
        level = try container.decode(String.self, forKey: .level)
        duration = try container.decode(String.self, forKey: .duration)
        
        // 추가 필드
        templateId = try container.decodeIfPresent(String.self, forKey: .templateId)
        isRoutine = try container.decodeIfPresent(Bool.self, forKey: .isRoutine)
        
        // Firebase Timestamp 필드 처리
        if let timestamp = try? container.decodeIfPresent(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = nil
        }
    }
    
    // 커스텀 인코더 메서드 추가
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // ID는 필요한 경우만 인코딩
        if let id = id {
            try container.encode(id, forKey: .id)
        }
        
        try container.encode(name, forKey: .name)
        try container.encode(scheduledDays, forKey: .scheduledDays)
        try container.encode(exercises, forKey: .exercises)
        
        // notes는 소문자 버전으로만 인코딩
        if let notes = notes {
            try container.encode(notes, forKey: .notes)
        }
        
        try container.encode(isPremium, forKey: .isPremium)
        try container.encode(level, forKey: .level)
        try container.encode(duration, forKey: .duration)
        
        // 추가 필드는 있는 경우만 인코딩
        if let templateId = templateId {
            try container.encode(templateId, forKey: .templateId)
        }
        
        if let isRoutine = isRoutine {
            try container.encode(isRoutine, forKey: .isRoutine)
        }
        
        // Date는 Timestamp로 인코딩하지 않고 생략
        // Firestore에 저장할 때는 별도 처리 필요
    }
    
    // 기본 이니셜라이저 유지
    init(id: String? = nil, name: String, scheduledDays: [String], exercises: [WorkoutExercise], 
         notes: String? = nil, isPremium: Bool, level: String, duration: String,
         templateId: String? = nil, isRoutine: Bool? = nil, createdAt: Date? = nil) {
        self.id = id
        self.name = name
        self.scheduledDays = scheduledDays
        self.exercises = exercises
        self.notes = notes
        self.isPremium = isPremium
        self.level = level
        self.duration = duration
        self.templateId = templateId
        self.isRoutine = isRoutine
        self.createdAt = createdAt
    }
    
    static var mock: WorkoutTemplate {
        WorkoutTemplate(
            id: "template_001",
            name: "Beginner Full-Body",
            scheduledDays: ["Monday", "Wednesday", "Friday"],
            exercises: [
                WorkoutExercise(
                    name: "Bench Press",
                    part: "chest",
                    key: "benchpress",
                    sets: [
                        ExerciseSet(reps: 12, weight: 50.0),
                        ExerciseSet(reps: 10, weight: 52.5),
                        ExerciseSet(reps: 8, weight: 55.0)
                    ],
                    restTime: 60
                ),
                WorkoutExercise(
                    name: "Pull-Up",
                    part: "back",
                    key: "pull-up",
                    sets: [
                        ExerciseSet(reps: 10, weight: 0.0),
                        ExerciseSet(reps: 8, weight: 0.0)
                    ],
                    restTime: 45
                )
            ],
            notes: "Ideal for beginners",
            isPremium: false,
            level: "Beginner",
            duration: "4 weeks",
            templateId: "template_1",
            isRoutine: true
        )
    }
} 