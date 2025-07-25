// GeniusParentingAISwift/CommunityViewModel.swift
import Foundation
import KeychainAccess
import UIKit

@MainActor
class CommunityViewModel: ObservableObject {
    @Published var postRowViewModels: [PostRowViewModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isLoadingMore = false
    private var currentPage = 1
    private var totalPages = 1
    
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
                self.currentPage = 1
                self.totalPages = 1
            }

            // Perform the fetch operations.
            await fetchCurrentUser()
            // We must check for cancellation after each async step.
            try Task.checkCancellation()

            if self.currentUser != nil {
                await fetchUserLikes()
            }
            try Task.checkCancellation()

            await fetchPostsAndCreateViewModels(isInitialLoad: true)
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

    func fetchMorePostsIfNeeded(currentItem item: PostRowViewModel?) {
        guard let item = item, !isLoadingMore, currentPage < totalPages else {
            return
        }

        let thresholdIndex = postRowViewModels.index(postRowViewModels.endIndex, offsetBy: -5)
        if postRowViewModels.firstIndex(where: { $0.id == item.id }) == thresholdIndex {
            Task {
                await fetchPostsAndCreateViewModels()
            }
        }
    }
    
    private func fetchPostsAndCreateViewModels(isInitialLoad: Bool = false) async {
        if isInitialLoad {
            currentPage = 1
        } else {
            guard currentPage < totalPages else { return }
            currentPage += 1
            isLoadingMore = true
        }

        do {
            // A single, clean call to the StrapiService.
            let response = try await StrapiService.shared.fetchPosts(page: currentPage, pageSize: 25)
            let posts = response.data ?? []
            
            // Clean log showing pagination info, which is useful for debugging.
            if let pagination = response.meta?.pagination {
                print("Fetched page \(pagination.page)/\(pagination.pageCount). Total posts: \(pagination.total).")
                self.totalPages = pagination.pageCount
            }
            
            let newViewModels = posts.map { post in
                PostRowViewModel(
                    post: post,
                    isLiked: self.userLikes.keys.contains(post.id),
                    communityViewModel: self
                )
            }
            
            if isInitialLoad {
                self.postRowViewModels = newViewModels
            } else {
                self.postRowViewModels.append(contentsOf: newViewModels)
            }

        } catch {
            if (error as? URLError)?.code != .cancelled {
                 errorMessage = "Failed to refresh posts: \(error.localizedDescription)"
                 print("Failed to fetch posts: \(error)")
            }
        }
        isLoadingMore = false
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
        if let user = SessionManager.shared.currentUser {
            self.currentUser = user
            return
        }

        do {
            let user = try await NetworkManager.shared.fetchUser()
            self.currentUser = user
            SessionManager.shared.currentUser = user
        } catch {
            print("CommunityViewModel: Failed to fetch current user: \(error.localizedDescription)")
            self.errorMessage = "Could not load user data."
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
        // --- ADDED LOGGING ---
        if currentUser == nil {
            print("⚠️ createPost called but currentUser is nil. Attempting to fetch user...")
            await fetchCurrentUser()
        }
        
        guard let token = keychain["jwt"], let userId = currentUser?.id else {
            print("❌ createPost failed: User not authenticated.")
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }

        // --- ADDED LOGGING ---
        print("✅ Creating post for User ID: \(userId)")

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
        
        // --- ADDED LOGGING ---
        print("📤 Sending createPost request with payload: \(requestBody)")
        
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
