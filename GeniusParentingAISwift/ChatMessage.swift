//
//  ChatMessage.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/6/7.
//

import Foundation

/// Represents a single message in the chat view.
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
}

/// A Codable struct to decode the JSON response from the chatbot backend.
struct BotResponse: Codable {
    let answer: String
}
