// TopicViewModel.swift

import Foundation

@MainActor
class TopicViewModel: ObservableObject {
    @Published var topic: Topic?
    @Published var isLoading: Bool = true
    @Published var errorMessage: String? = nil
    
    private let strapiUrl = "\(Config.strapiBaseUrl)/api"
    // The keychain property is no longer needed here.
    
    func fetchTopic(topicId: Int) async {
        isLoading = true
        errorMessage = nil
        
        let populateQuery = "populate[icon_image]=*&populate[content][populate]=image_file,video_file,thumbnail"
        
        guard let url = URL(string: "\(strapiUrl)/topics/\(topicId)?\(populateQuery)") else {
            errorMessage = "Internal error: Invalid URL."
            isLoading = false
            return
        }
        
        do {
            // A single, clean call to the NetworkManager.
            // The NetworkManager now handles token attachment, response validation, and detailed error logging.
            self.topic = try await NetworkManager.shared.fetchSingle(from: url)
        } catch {
            // The catch block is now simpler, only responsible for updating the UI state.
            errorMessage = "Fetch error: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func refreshTopic(topicId: Int) async {
        // This function simply calls the existing fetch method.
        await fetchTopic(topicId: topicId)
    }
}
