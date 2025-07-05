// ChatMessage.swift

import Foundation

/// Represents a single message in the chat view.
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
}

// REMOVED: The old BotResponse struct is no longer needed.
// struct BotResponse: Codable { ... }

// MARK: - OpenAI Completion Response Models
// Represents the top-level structure of the OpenAI chat completion response.
struct OpenAICompletionResponse: Codable {
    let choices: [Choice]
}

// Represents a single choice in the OpenAI response.
struct Choice: Codable {
    let message: ResponseMessage
}

// Represents the message object containing the assistant's reply.
struct ResponseMessage: Codable {
    let role: String
    let content: String
}
