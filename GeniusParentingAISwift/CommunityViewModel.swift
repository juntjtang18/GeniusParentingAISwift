// CommunityViewModel.swift

import Foundation
import KeychainAccess

@MainActor
class CommunityViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = true
    @Published var errorMessage: String? = nil

    private let strapiUrl = "\(Config.strapiBaseUrl)/api"
    private let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")

    func fetchPosts() async {
        isLoading = true
        errorMessage = nil

        guard let token = keychain["jwt"] else {
            errorMessage = "Authentication token not found."
            isLoading = false
            return
        }

        let query = "sort[0]=create_time:desc&populate[users_permissions_user][populate][user_profile]=true&populate[media]=true&populate[likes][count]=true"
        guard let url = URL(string: "\(strapiUrl)/posts?\(query)") else {
            errorMessage = "Invalid URL."
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let rawJSONString = String(data: data, encoding: .utf8) {
                print("--- RAW POSTS JSON RESPONSE ---\n\(rawJSONString)\n---------------------------------")
            }

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                errorMessage = "Server error with status code: \(statusCode)."
                isLoading = false
                return
            }

            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(StrapiListResponse<Post>.self, from: data)
            
            // FIX: Use ?? [] to safely unwrap the now-optional data property.
            self.posts = decodedResponse.data ?? []
            
        } catch {
            errorMessage = "Failed to fetch posts: \(error.localizedDescription)"
             if let decodingError = error as? DecodingError {
               print("CommunityViewModel: Decoding error details: \(decodingError)")
           }
        }
        isLoading = false
    }
}
