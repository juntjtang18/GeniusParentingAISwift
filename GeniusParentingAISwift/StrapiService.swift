// GeniusParentingAISwift/StrapiService.swift
import Foundation
import os

struct CommentPostPayload: Codable {
    let data: CommentPostData
}

struct CommentPostData: Codable {
    let message: String
    let post: Int
}

class StrapiService {
    
    static let shared = StrapiService()
    private let logger = Logger(subsystem: "com.geniusparentingai.GeniusParentingAISwift", category: "StrapiService")

    private init() {}

    // MARK: - Authentication & User Management

    func login(credentials: LoginCredentials) async throws -> AuthResponse {
        logger.debug("StrapiService: Attempting login.")
        return try await NetworkManager.shared.login(credentials: credentials)
    }

    func fetchCurrentUser() async throws -> StrapiUser {
        logger.debug("StrapiService: Fetching current user profile.")
        return try await NetworkManager.shared.fetchUser()
    }
    
    // ADDED: Method to fetch extended user profile
    func fetchUserProfile() async throws -> UserProfileApiResponse {
        logger.debug("StrapiService: Fetching user profile from /mine endpoint.")
        guard let url = URL(string: "\(Config.strapiBaseUrl)/api/user-profiles/mine") else {
            throw URLError(.badURL)
        }
        return try await NetworkManager.shared.fetchDirect(from: url)
    }

    // ADDED: Method to update user account details
    func updateUserAccount(userId: Int, payload: UserUpdatePayload) async throws -> StrapiUser {
        logger.debug("StrapiService: Updating user account for ID \(userId).")
        guard let url = URL(string: "\(Config.strapiBaseUrl)/api/users/\(userId)") else {
            throw URLError(.badURL)
        }
        return try await NetworkManager.shared.put(to: url, body: payload)
    }

    // ADDED: Method to update user profile details
    func updateUserProfile(payload: ProfileUpdatePayload) async throws -> UserProfileApiResponse {
        logger.debug("StrapiService: Updating user profile via /mine endpoint.")
        guard let url = URL(string: "\(Config.strapiBaseUrl)/api/user-profiles/mine") else {
            throw URLError(.badURL)
        }
        return try await NetworkManager.shared.put(to: url, body: payload)
    }


    // MARK: - Post & Course Management
    
    // ... (The rest of the file remains unchanged)
    func fetchPosts(page: Int, pageSize: Int) async throws -> StrapiListResponse<Post> {
        logger.debug("StrapiService: Fetching posts via custom endpoint, page \(page).")
        guard var components = URLComponents(string: "\(Config.strapiBaseUrl)/api/getposts") else {
            throw URLError(.badURL)
        }
        components.queryItems = [
            URLQueryItem(name: "sort", value: "createdAt:desc"),
            URLQueryItem(name: "pagination[page]", value: String(page)),
            URLQueryItem(name: "pagination[pageSize]", value: String(pageSize))
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        return try await NetworkManager.shared.fetchDirect(from: url)
    }
    
    func fetchPostDetails(postId: Int, page: Int, pageSize: Int) async throws -> StrapiSingleResponse<Post> {
        logger.debug("StrapiService: Fetching details for post ID \(postId).")
        guard var components = URLComponents(string: "\(Config.strapiBaseUrl)/api/posts/\(postId)") else {
            throw URLError(.badURL)
        }
        components.queryItems = [
            URLQueryItem(name: "pagination[page]", value: String(page)),
            URLQueryItem(name: "pagination[pageSize]", value: String(pageSize))
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        return try await NetworkManager.shared.fetchDirect(from: url)
    }

    func fetchCoursesForCategory(categoryId: Int, page: Int, pageSize: Int) async throws -> StrapiListResponse<Course> {
        logger.debug("StrapiService: Fetching courses for category ID \(categoryId), page \(page).")

        let populateQuery = "populate=icon_image,translations"
        let filterQuery = "filters[coursecategory][id][$eq]=\(categoryId)"
        let sortQuery = "sort[0]=order:asc&sort[1]=title:asc"

        guard var components = URLComponents(string: "\(Config.strapiBaseUrl)/api/courses") else {
            throw URLError(.badURL)
        }
        
        components.query = "\(populateQuery)&\(filterQuery)&\(sortQuery)"

        return try await NetworkManager.shared.fetchPage(baseURLComponents: components, page: page, pageSize: pageSize)
    }

    // MARK: - Comment Management

    func fetchCommentsForPost(postId: Int, page: Int, pageSize: Int) async throws -> StrapiListResponse<Comment> {
        logger.debug("StrapiService: Fetching comments for post ID \(postId) via custom endpoint, page \(page).")

        guard var components = URLComponents(string: "\(Config.strapiBaseUrl)/api/getcomments") else {
            throw URLError(.badURL)
        }
        
        components.queryItems = [
            URLQueryItem(name: "postId", value: String(postId)),
            URLQueryItem(name: "pagination[page]", value: String(page)),
            URLQueryItem(name: "pagination[pageSize]", value: String(pageSize))
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        return try await NetworkManager.shared.fetchDirect(from: url)
    }

    func postComment(payload: CommentPostPayload) async throws -> StrapiSingleResponse<Comment> {
        logger.debug("StrapiService: Posting new comment.")
        guard let url = URL(string: "\(Config.strapiBaseUrl)/api/comments") else {
            throw URLError(.badURL)
        }
        return try await NetworkManager.shared.post(to: url, body: payload)
    }
    
    func fetchPlans() async throws -> StrapiListResponse<Plan> {
        logger.debug("StrapiService: Fetching subscription plans.")
        guard let url = URL(string: "\(Config.strapiBaseUrl)/api/plans") else {
            throw URLError(.badURL)
        }
        return try await NetworkManager.shared.fetchDirect(from: url)
    }

    // MARK: - Subscription Management

    func activateSubscription(receipt: String) async throws -> SubscriptionActivationResponse {
        logger.debug("StrapiService: Activating subscription.")
        guard let url = URL(string: "\(Config.subscriptionSubsystemBaseUrl)/api/v1/subscriptions/activate") else {
            throw URLError(.badURL)
        }
        let payload = SubscriptionActivationPayload(apple_receipt: receipt)
        return try await NetworkManager.shared.post(to: url, body: payload)
    }
}
