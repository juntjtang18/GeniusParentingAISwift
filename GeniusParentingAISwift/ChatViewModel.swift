// ChatViewModel.swift

import Foundation
import KeychainAccess

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isAwaitingResponse: Bool = false
    
    private let keychain = Keychain(service: Config.keychainService)
    private let strapiUrl = "\(Config.strapiBaseUrl)/api"

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
        // 1. Use the new Strapi endpoint URL
        guard let url = URL(string: "\(strapiUrl)/openai/completion") else {
            addErrorMessage(text: "Error: Invalid backend URL")
            return
        }

        // 2. Get the JWT token for authorization
        guard let token = keychain["jwt"] else {
            addErrorMessage(text: "Error: You must be logged in to use the AI assistant.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 3. Add the Bearer token to the authorization header
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // 4. Set the request body with the "prompt" key
        let body: [String: Any] = ["prompt": userInput]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                addErrorMessage(text: "An error occurred (Status: \(statusCode)). Please try again.")
                return
            }

            // 5. Decode the new OpenAICompletionResponse
            let openAIResponse = try JSONDecoder().decode(OpenAICompletionResponse.self, from: data)

            // 6. Extract the assistant's message from the nested structure
            if let botContent = openAIResponse.choices.first?.message.content {
                let botMessage = ChatMessage(content: botContent.trimmingCharacters(in: .whitespacesAndNewlines), isUser: false)
                messages.append(botMessage)
            } else {
                addErrorMessage(text: "Error: Received an empty response from the AI.")
            }
        } catch {
            addErrorMessage(text: "Error: Could not process the server's response.")
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
