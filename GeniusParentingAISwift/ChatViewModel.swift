//
//  ChatViewModel.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/6/7.
//

import Foundation

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isAwaitingResponse: Bool = false

    /// Adds the user's message and triggers the bot response fetch.
    func sendMessage(text: String) {
        let userMessage = ChatMessage(content: text, isUser: true)
        messages.append(userMessage)

        isAwaitingResponse = true

        Task {
            await fetchBotResponse(userInput: text)
        }
    }

    /// Fetches a response from the chatbot backend.
    private func fetchBotResponse(userInput: String) async {
        guard let url = URL(string: "https://parentgenius-backend-852311377699.us-west1.run.app/ask") else {
            addErrorMessage(text: "Error: Invalid backend URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["question": userInput]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let botResponse = try? JSONDecoder().decode(BotResponse.self, from: data) {
                let botMessage = ChatMessage(content: botResponse.answer, isUser: false)
                messages.append(botMessage)
            } else {
                addErrorMessage(text: "Error: Could not decode server response.")
            }
        } catch {
            addErrorMessage(text: "Error: \(error.localizedDescription)")
        }

        isAwaitingResponse = false
    }
    
    /// A helper function to add error messages to the chat view.
    private func addErrorMessage(text: String) {
        let errorMessage = ChatMessage(content: text, isUser: false)
        messages.append(errorMessage)
        isAwaitingResponse = false
    }
}
