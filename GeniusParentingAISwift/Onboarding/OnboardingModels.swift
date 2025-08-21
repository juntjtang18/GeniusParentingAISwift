//
//  Answer.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/8/20.
//


// OnboardingModels.swift

import Foundation

// Represents a single answer option for a question
struct Answer: Identifiable, Codable, Hashable {
    let id: Int              // <-- Use Strapi’s numeric ID here
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
    // NEW
    let imageURL: URL?
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

    // NEW: reuse StrapiRelation<Media> from Models.swift
    let image: StrapiRelation<Media>?    // ← add this

    enum CodingKeys: String, CodingKey {
        case title, description, locale, createdAt, updatedAt, image
        case powerTip = "power_tip"
        case psId = "ps_id"
    }
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
            description: result.attributes.description,
            powerTip: result.attributes.powerTip,
            imageURL: absoluteURL
        )
    }
}
// MARK: - Strapi: Personality Questions

/// Strapi entry: /api/pers-questions
struct PersQuestion: Codable, Identifiable {
    let id: Int
    let attributes: Attributes
    struct Attributes: Codable {
        let order: Int
        let question: String
        let answer: [PersAnswerRaw]? // populated via populate[answer]=*
        let createdAt: String?
        let updatedAt: String?
        let locale: String?
    }
}


struct PersAnswerRaw: Codable, Hashable, Identifiable {
    let id: Int
    let ans_id: String
    let ans_text: String
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
