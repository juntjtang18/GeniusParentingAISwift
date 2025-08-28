//
//  OnboardingModels.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/8/20.
//

import Foundation
import SwiftUI // Assuming this is needed for your project

// Represents a single answer option for a question
struct Answer: Identifiable, Codable, Hashable {
    let id: Int
    let ans_id: String
    let ans_text: String
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
    let imageURL: URL?
}

// Convenience bridge so UI that expects QuizResult can still work
extension QuizResult {
    init(from result: PersonalityResult) {
        let path = result.attributes.image?.data?.attributes.url
        let absoluteURL: URL? = {
            guard let path else { return nil }
            if path.hasPrefix("http") { return URL(string: path) }
            return URL(string: Config.strapiBaseUrl + path)
        }()

        self.init(
            title: result.attributes.title,
            description: result.attributes.description, // ✅ FIX: Provide a default empty string
            powerTip: result.attributes.powerTip,       // ✅ FIX: Provide a default empty string
            imageURL: absoluteURL
        )
    }
}

// Bridge Strapi → UI
extension Question {
    init(from s: PersQuestion) {
        let answers = (s.attributes.answer ?? []).map {
            Answer(id: $0.id, ans_id: $0.ans_id, ans_text: $0.ans_text)
        }
        self.init(questionText: s.attributes.question, answers: answers)
    }
}
