// CommunityViewModel.swift

import Foundation
import KeychainAccess

@MainActor
class CommunityViewModel: ObservableObject {
    // This now holds the view models for each row, not the raw data
    @Published var postRowViewModels: [PostRowViewModel] = []
    
    @Published var isLoading: Bool = true
    @Published var errorMessage: String? = nil
    
    private var userLikes: [Int: Int] = [:]
    private var currentUser: StrapiUser?

    private let strapiUrl = "\(Config.strapiBaseUrl)/api"
    private let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")

    func initialLoad() async {
        isLoading = true
        await fetchCurrentUser()
        if self.currentUser != nil {
            await fetchUserLikes()
        }
        await fetchPostsAndCreateViewModels()
        isLoading = false
    }
    
    private func fetchPostsAndCreateViewModels() async {
        guard let token = keychain["jwt"] else {
            errorMessage = "Authentication token not found."
            return
        }
        let query = "sort[0]=create_time:desc&populate[users_permissions_user][populate][user_profile]=true&populate[media]=true&populate[likes][count]=true"
        guard let url = URL(string: "\(strapiUrl)/posts?\(query)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let posts = try JSONDecoder().decode(StrapiListResponse<Post>.self, from: data).data ?? []
            
            // Convert raw Post data into PostRowViewModels
            self.postRowViewModels = posts.map { post in
                PostRowViewModel(
                    post: post,
                    isLiked: self.userLikes.keys.contains(post.id),
                    communityViewModel: self
                )
            }
        } catch {
            errorMessage = "Failed to fetch posts: \(error.localizedDescription)"
        }
    }

    func toggleLikeOnServer(postId: Int) async {
        guard let userId = currentUser?.id, let token = keychain["jwt"] else { return }

        if let likeId = userLikes[postId] {
            // UNLIKE
            guard let url = URL(string: "\(strapiUrl)/likes/\(likeId)") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            if let (_, response) = try? await URLSession.shared.data(for: request),
               let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                userLikes.removeValue(forKey: postId)
            }
        } else {
            // LIKE
            guard let url = URL(string: "\(strapiUrl)/likes") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: Any] = ["data": ["post": postId, "users_permissions_user": userId]]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            if let (data, response) = try? await URLSession.shared.data(for: request),
               let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let newLikeResponse = try? JSONDecoder().decode(StrapiSingleResponse<Like>.self, from: data) {
                    userLikes[postId] = newLikeResponse.data.id
                }
            }
        }
    }
    
    private func fetchCurrentUser() async {
        guard let token = keychain["jwt"] else { return }
        guard let url = URL(string: "\(strapiUrl)/users/me") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let (data, _) = try? await URLSession.shared.data(for: request) {
            self.currentUser = try? JSONDecoder().decode(StrapiUser.self, from: data)
        }
    }

    private func fetchUserLikes() async {
        guard let userId = currentUser?.id, let token = keychain["jwt"] else { return }
        
        let query = "filters[users_permissions_user][id][$eq]=\(userId)&populate[post][fields][0]=id"
        guard let url = URL(string: "\(strapiUrl)/likes?\(query)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let (data, _) = try? await URLSession.shared.data(for: request) {
            if let response = try? JSONDecoder().decode(StrapiListResponse<Like>.self, from: data) {
                self.userLikes.removeAll()
                for like in response.data ?? [] {
                    if let postId = like.attributes.post?.data?.id {
                        self.userLikes[postId] = like.id
                    }
                }
            }
        }
    }
}
