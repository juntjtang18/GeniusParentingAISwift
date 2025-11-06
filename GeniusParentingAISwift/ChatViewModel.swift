// ChatViewModel.swift

import Foundation

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isAwaitingResponse: Bool = false
    
    private let strapiUrl = "\(Config.strapiBaseUrl)/api"
    // The keychain property is no longer needed here.

    /// Adds the user's message and triggers the bot response fetch.
    func sendMessage(text: String) {
        let userMessage = ChatMessage(content: text, isUser: true)
        messages.append(userMessage)
        isAwaitingResponse = true
        Task {
            await fetchBotResponse(userInput: text)
        }
    }

    /// Fetches a response from the Strapi OpenAI bridge endpoint.
    private func fetchBotResponse(userInput: String) async {
        guard let url = URL(string: "\(strapiUrl)/openai/completion") else {
            addErrorMessage(text: String(localized: "Error: Invalid backend URL"))
            return
        }

        // The request body now uses a simple struct.
        let body = ["prompt": userInput]

        do {
            // A single, clean call to the NetworkManager's generic post method.
            let openAIResponse: OpenAICompletionResponse = try await NetworkManager.shared.post(to: url, body: body)

            if let botContent = openAIResponse.choices.first?.message.content {
                let botMessage = ChatMessage(content: botContent.trimmingCharacters(in: .whitespacesAndNewlines), isUser: false)
                messages.append(botMessage)
            } else {
                addErrorMessage(text: "Error: Received an empty response from the AI.")
            }
        } catch {
            addErrorMessage(text: "Error: \(error.localizedDescription)")
            print("AI Fetch Error: \(error)")
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
