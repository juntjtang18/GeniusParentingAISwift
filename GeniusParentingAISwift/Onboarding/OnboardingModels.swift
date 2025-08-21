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
// MARK: - Personality Results (from Strapi)

struct PersonalityResult: Codable, Identifiable, Hashable {
    let id: Int
    let attributes: PersonalityResultAttributes
}

struct PersonalityResultAttributes: Codable, Hashable {
    let title: String
    let description: String
    let powerTip: String
    let createdAt: String
    let updatedAt: String
    let locale: String?
    let psId: String?

    enum CodingKeys: String, CodingKey {
        case title, description, locale, createdAt, updatedAt
        case powerTip = "power_tip"
        case psId = "ps_id"
    }
}

// Convenience bridge so UI that expects QuizResult can still work
extension QuizResult {
    init(from result: PersonalityResult) {
        self.init(
            title: result.attributes.title,
            description: result.attributes.description,
            powerTip: result.attributes.powerTip
        )
    }
}
