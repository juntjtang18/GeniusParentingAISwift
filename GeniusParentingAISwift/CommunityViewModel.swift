import Foundation
import KeychainAccess
import UIKit

@MainActor
class CommunityViewModel: ObservableObject {
    @Published var postRowViewModels: [PostRowViewModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var userLikes: [Int: Int] = [:]
    private var currentUser: StrapiUser?

    private let strapiUrl = "\(Config.strapiBaseUrl)/api"
    private let keychain = Keychain(service: Config.keychainService)
    
    // Task to manage the fetch operation, allowing cancellation.
    private var fetchTask: Task<Void, Error>?

    func initialLoad() async {
        // Cancel the previous task if it's still running.
        fetchTask?.cancel()

        // Create a new task to fetch posts.
        fetchTask = Task {
            // This ensures the code inside runs on the main actor.
            await MainActor.run {
                self.isLoading = true
                self.errorMessage = nil
            }

            // Perform the fetch operations.
            await fetchCurrentUser()
            // We must check for cancellation after each async step.
            try Task.checkCancellation()

            if self.currentUser != nil {
                await fetchUserLikes()
            }
            try Task.checkCancellation()

            await fetchPostsAndCreateViewModels()
        }

        do {
            try await fetchTask?.value
        } catch {
            if !(error is CancellationError) {
                // Only show an error if it's not a cancellation error.
                await MainActor.run {
                    errorMessage = "Failed to refresh posts: \(error.localizedDescription)"
                }
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    private func fetchPostsAndCreateViewModels() async {
        guard let token = keychain["jwt"] else {
            errorMessage = "Authentication token not found."
            return
        }
        
        let query = "sort[0]=createdAt:desc&populate[users_permissions_user][populate][user_profile]=true&populate[media]=true&populate[likes][count]=true"
        guard let url = URL(string: "\(strapiUrl)/posts?\(query)") else { return }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(StrapiListResponse<Post>.self, from: data)
            let posts = response.data ?? []
            
            // Clean log showing pagination info, which is useful for debugging.
            if let pagination = response.meta?.pagination {
                print("Fetched page \(pagination.page)/\(pagination.pageCount). Total posts: \(pagination.total).")
            }
            
            let newViewModels = posts.map { post in
                PostRowViewModel(
                    post: post,
                    isLiked: self.userLikes.keys.contains(post.id),
                    communityViewModel: self
                )
            }
            
            self.postRowViewModels = newViewModels

        } catch {
            if (error as? URLError)?.code != .cancelled {
                 errorMessage = "Failed to refresh posts: \(error.localizedDescription)"
                 print("Failed to fetch posts: \(error)")
            }
        }
    }

    // ... The rest of your ViewModel methods remain unchanged ...
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

    func createPost(content: String, mediaData: [Data]) async throws {
        guard let token = keychain["jwt"], let userId = currentUser?.id else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }

        var mediaIds: [Int] = []
        if !mediaData.isEmpty {
            mediaIds = try await uploadMedia(mediaData: mediaData, token: token)
        }

        guard let url = URL(string: "\(strapiUrl)/posts") else {
            throw NSError(domain: "URLError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL for creating post."])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let postData: [String: Any] = [
            "content": content,
            "users_permissions_user": userId,
            "media": mediaIds
        ]
        
        let requestBody: [String: Any] = ["data": postData]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // FIXED: Replaced 'responseData' with '_' to silence the "never used" warning.
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "NetworkError", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create post."])
        }
    }

    private func uploadMedia(mediaData: [Data], token: String) async throws -> [Int] {
        guard let url = URL(string: "\(Config.strapiBaseUrl)/api/upload") else {
            throw NSError(domain: "URLError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid upload URL."])
        }
        
        var uploadedMediaIDs: [Int] = []
        
        for (index, data) in mediaData.enumerated() {
            let boundary = UUID().uuidString
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var body = Data()
            let filename = "upload_\(index+1).jpg"
            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = body
            
            let (responseData, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                 print("❌ [Debug] Upload Failed Response: \(response)")
                 print("❌ [Debug] Upload Failed Response Data: \(String(data: responseData, encoding: .utf8) ?? "Could not decode response data")")
                throw NSError(domain: "NetworkError", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Failed to upload media."])
            }
            
            let uploadedFiles = try JSONDecoder().decode([UploadResponseMedia].self, from: responseData)
            uploadedMediaIDs.append(contentsOf: uploadedFiles.map { $0.id })
        }
        
        return uploadedMediaIDs
    }
}
