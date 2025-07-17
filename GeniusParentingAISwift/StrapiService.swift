// GeniusParentingAISwift/StrapiService.swift
import Foundation
import os

/// A data structure for sending a new comment to the server.
struct CommentPostPayload: Codable {
    let data: CommentPostData
}

struct CommentPostData: Codable {
    let message: String
    let post: Int
}


/// A service layer for interacting with the Strapi backend API.
class StrapiService {
    
    static let shared = StrapiService()
    private let logger = Logger(subsystem: "com.geniusparentingai.GeniusParentingAISwift", category: "StrapiService")

    private init() {}

    // MARK: - Authentication & User Management

    /// Attempts to log in the user with the provided credentials.
    /// - Parameter credentials: The user's login identifier and password.
    /// - Returns: An `AuthResponse` containing the JWT and user data.
    func login(credentials: LoginCredentials) async throws -> AuthResponse {
        logger.debug("StrapiService: Attempting login.")
        return try await NetworkManager.shared.login(credentials: credentials)
    }

    /// Fetches the profile for the currently authenticated user.
    /// - Returns: A `StrapiUser` object.
    func fetchCurrentUser() async throws -> StrapiUser {
        logger.debug("StrapiService: Fetching current user profile.")
        return try await NetworkManager.shared.fetchUser()
    }

    // MARK: - Post & Course Management

    /// Fetches a paginated list of posts using the custom 'getposts' endpoint.
    /// - Returns: A `StrapiListResponse` containing the posts and pagination metadata.
    func fetchPosts(page: Int, pageSize: Int) async throws -> StrapiListResponse<Post> {
        logger.debug("StrapiService: Fetching posts via custom endpoint, page \(page).")
        guard var components = URLComponents(string: "\(Config.strapiBaseUrl)/api/getposts") else {
            throw URLError(.badURL)
        }
        // Ensure sorting is always applied, and add the flat pagination parameters
        // that the custom controller expects.
        components.queryItems = [
            URLQueryItem(name: "sort", value: "createdAt:desc"),
            URLQueryItem(name: "pagination[page]", value: String(page)),
            URLQueryItem(name: "pagination[pageSize]", value: String(pageSize))
        ]
        
        // Since we are manually adding pagination params, we call fetchDirect, not fetchPage.
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        return try await NetworkManager.shared.fetchDirect(from: url)
    }
    
    /// Fetches a single post with all its details using the custom findOne endpoint.
    /// - Parameter postId: The ID of the post to fetch.
    /// - Returns: A `Post` object.
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


    /// Fetches a paginated list of courses for a specific category, sorted by order.
    /// - Parameters:
    ///   - categoryId: The ID of the category to fetch courses for.
    ///   - page: The page number to fetch.
    ///   - pageSize: The number of items per page.
    /// - Returns: A `StrapiListResponse` containing the courses and pagination metadata.
    func fetchCoursesForCategory(categoryId: Int, page: Int, pageSize: Int) async throws -> StrapiListResponse<Course> {
        logger.debug("StrapiService: Fetching courses for category ID \(categoryId), page \(page).")

        let populateQuery = "populate=icon_image,translations"
        let filterQuery = "filters[coursecategory][id][$eq]=\(categoryId)"
        let sortQuery = "sort[0]=order:asc&sort[1]=title:asc" // Sort by order, then by title.

        guard var components = URLComponents(string: "\(Config.strapiBaseUrl)/api/courses") else {
            throw URLError(.badURL)
        }
        
        components.query = "\(populateQuery)&\(filterQuery)&\(sortQuery)"

        return try await NetworkManager.shared.fetchPage(baseURLComponents: components, page: page, pageSize: pageSize)
    }

    // MARK: - Comment Management

    /// Fetches a paginated list of comments for a specific post using the custom 'getcomments' endpoint.
    /// - Parameters:
    ///   - postId: The ID of the post to fetch comments for.
    ///   - page: The page number to fetch.
    ///   - pageSize: The number of items per page.
    /// - Returns: A `StrapiListResponse` containing the comments and pagination metadata.
    func fetchCommentsForPost(postId: Int, page: Int, pageSize: Int) async throws -> StrapiListResponse<Comment> {
        logger.debug("StrapiService: Fetching comments for post ID \(postId) via custom endpoint, page \(page).")

        guard var components = URLComponents(string: "\(Config.strapiBaseUrl)/api/getcomments") else {
            throw URLError(.badURL)
        }
        
        // Add the postId as a query parameter for the custom route
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


    /// Posts a new comment to the server.
    /// - Parameter payload: The comment data to be sent.
    /// - Returns: The newly created `Comment` object wrapped in a StrapiSingleResponse.
    func postComment(payload: CommentPostPayload) async throws -> StrapiSingleResponse<Comment> {
        logger.debug("StrapiService: Posting new comment.")
        guard let url = URL(string: "\(Config.strapiBaseUrl)/api/comments") else {
            throw URLError(.badURL)
        }
        return try await NetworkManager.shared.post(to: url, body: payload)
    }
    /// Fetches the available subscription plans from the main Strapi server.
    /// - Returns: A `StrapiListResponse` containing the plans.
    func fetchPlans() async throws -> StrapiListResponse<Plan> {
        logger.debug("StrapiService: Fetching subscription plans.")
        guard let url = URL(string: "\(Config.strapiBaseUrl)/api/plans") else {
            throw URLError(.badURL)
        }
        // Use fetchDirect since the response is a direct object, not wrapped in another "data" key.
        return try await NetworkManager.shared.fetchDirect(from: url)
    }
    
}
