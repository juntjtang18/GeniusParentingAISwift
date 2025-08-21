//
//  Answer.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/8/20.
//


// OnboardingModels.swift

import Foundation

// Represents a single answer option for a question
struct Answer: Identifiable, Hashable {
    let id: String // e.g., "A", "B", "C", "D"
    let text: String
}

// Represents a single question with its possible answers
struct Question: Identifiable {
    let id = UUID()
    let questionText: String
    let answers: [Answer]
}

// Represents the final result of the quiz
struct QuizResult {
    let title: String
    let description: String
    let powerTip: String
}