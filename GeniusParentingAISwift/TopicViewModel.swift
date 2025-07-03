// TopicViewModel.swift

import Foundation
import KeychainAccess

@MainActor
class TopicViewModel: ObservableObject {
    @Published var topic: Topic?
    @Published var isLoading: Bool = true
    @Published var errorMessage: String? = nil
    
    private let strapiUrl = "\(Config.strapiBaseUrl)/api"
    private let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")
    
    func fetchTopic(topicId: Int) async {
        isLoading = true
        errorMessage = nil
        
        guard let token = keychain["jwt"] else {
            errorMessage = "Authentication token not found."
            isLoading = false
            return
        }
        
        // Populate the content dynamic zone and its nested media files
        let populateQuery = "populate[icon_image]=*&populate[content][populate]=image_file,video_file,thumbnail"
        
        guard let url = URL(string: "\(strapiUrl)/topics/\(topicId)?\(populateQuery)") else {
            errorMessage = "Internal error: Invalid URL."
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                var detailedError = "Server error \(statusCode)."
                if let errData = try? JSONDecoder().decode(StrapiErrorResponse.self, from: data) {
                    detailedError = errData.error.message
                }
                errorMessage = detailedError
                isLoading = false
                return
            }
            let decoder = JSONDecoder()
            // REMOVED: decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decodedResponse = try decoder.decode(StrapiSingleResponse<Topic>.self, from: data)
            self.topic = decodedResponse.data
            
        } catch {
            if let decError = error as? DecodingError {
                print("Decoding Error in TopicViewModel: \(decError)")
                errorMessage = "Data parsing error. Check if the Swift models match the JSON response."
            } else {
                errorMessage = "Fetch error: \(error.localizedDescription)"
            }
        }
        isLoading = false
    }
    
    func refreshTopic(topicId: Int) async {
        // This function simply calls the existing fetch method.
        await fetchTopic(topicId: topicId)
    }
}
