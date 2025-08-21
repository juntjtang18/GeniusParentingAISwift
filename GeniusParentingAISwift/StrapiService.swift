// GeniusParentingAISwift/StrapiService.swift

import Foundation
// We no longer need to import `os` directly, as AppLogger handles it.

// These structs are used by the service, so they remain here.
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
    // Use the new AppLogger, configured for the "StrapiService" category from Logging.plist.
    private let logger = AppLogger(category: "StrapiService")

    private init() {}

    // MARK: - Authentication & User Management

    func login(credentials: LoginCredentials) async throws -> AuthResponse {
        let functionName = #function // Capture the function name for logging
        logger.info("[StrapiService::\(functionName)] - Attempting login for user: \(credentials.identifier)")
        do {
            let response = try await NetworkManager.shared.login(credentials: credentials)
            logger.info("[StrapiService::\(functionName)] - Login successful for user: \(response.user.username)")
            return response
        } catch {
            logger.error("[StrapiService::\(functionName)] - Login failed: \(error.localizedDescription)")
            throw error
        }
    }

    func fetchCurrentUser() async throws -> StrapiUser {
        let functionName = #function
        logger.info("[StrapiService::\(functionName)] - Fetching current user.")
        do {
            let user = try await NetworkManager.shared.fetchUser()
            logger.info("[StrapiService::\(functionName)] - Successfully fetched user: \(user.username)")
            return user
        } catch {
            logger.error("[StrapiService::\(functionName)] - Failed to fetch current user: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchUserProfile() async throws -> UserProfileApiResponse {
        let functionName = #function
        logger.info("[StrapiService::\(functionName)] - Fetching user profile from /mine endpoint.")
        do {
            // FIX: Added explicit type annotation
            let response: UserProfileApiResponse = try await NetworkManager.shared.fetchDirect(from: URL(string: "\(Config.strapiBaseUrl)/api/user-profiles/mine")!)
            logger.info("[StrapiService::\(functionName)] - Successfully fetched user profile.")
            return response
        } catch {
            logger.error("[StrapiService::\(functionName)] - Failed to fetch user profile: \(error.localizedDescription)")
            throw error
        }
    }

    func updateUserAccount(userId: Int, payload: UserUpdatePayload) async throws -> StrapiUser {
        let functionName = #function
        logger.info("[StrapiService::\(functionName)] - Updating user account for ID \(userId).")
        do {
            // FIX: Added explicit type annotation
            let updatedUser: StrapiUser = try await NetworkManager.shared.put(to: URL(string: "\(Config.strapiBaseUrl)/api/users/\(userId)")!, body: payload)
            logger.info("[StrapiService::\(functionName)] - Successfully updated user account for ID \(userId).")
            return updatedUser
        } catch {
            logger.error("[StrapiService::\(functionName)] - Failed to update user account for ID \(userId): \(error.localizedDescription)")
            throw error
        }
    }

    func updateUserProfile(payload: ProfileUpdatePayload) async throws -> UserProfileApiResponse {
        let functionName = #function
        logger.info("[StrapiService::\(functionName)] - Updating user profile via /mine endpoint.")
        do {
            // FIX: Added explicit type annotation
            let response: UserProfileApiResponse = try await NetworkManager.shared.put(to: URL(string: "\(Config.strapiBaseUrl)/api/user-profiles/mine")!, body: payload)
            logger.info("[StrapiService::\(functionName)] - Successfully updated user profile.")
            return response
        } catch {
            logger.error("[StrapiService::\(functionName)] - Failed to update user profile: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Post & Course Management

    func fetchPosts(page: Int, pageSize: Int) async throws -> StrapiListResponse<Post> {
        let functionName = #function
        logger.info("[StrapiService::\(functionName)] - Fetching posts, page \(page).")
        do {
            guard var components = URLComponents(string: "\(Config.strapiBaseUrl)/api/getposts") else { throw URLError(.badURL) }
            components.queryItems = [
                URLQueryItem(name: "sort", value: "createdAt:desc"),
                URLQueryItem(name: "pagination[page]", value: String(page)),
                URLQueryItem(name: "pagination[pageSize]", value: String(pageSize))
            ]
            // FIX: Added explicit type annotation
            let response: StrapiListResponse<Post> = try await NetworkManager.shared.fetchDirect(from: components.url!)
            logger.info("[StrapiService::\(functionName)] - Successfully fetched \(response.data?.count ?? 0) posts for page \(page).")
            return response
        } catch {
            logger.error("[StrapiService::\(functionName)] - Failed to fetch posts for page \(page): \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchPostDetails(postId: Int, page: Int, pageSize: Int) async throws -> StrapiSingleResponse<Post> {
        let functionName = #function
        logger.info("[StrapiService::\(functionName)] - Fetching details for post ID \(postId).")
        do {
            guard var components = URLComponents(string: "\(Config.strapiBaseUrl)/api/posts/\(postId)") else { throw URLError(.badURL) }
            components.queryItems = [
                URLQueryItem(name: "pagination[page]", value: String(page)),
                URLQueryItem(name: "pagination[pageSize]", value: String(pageSize))
            ]
            // FIX: Added explicit type annotation
            let response: StrapiSingleResponse<Post> = try await NetworkManager.shared.fetchDirect(from: components.url!)
            logger.info("[StrapiService::\(functionName)] - Successfully fetched details for post ID \(postId).")
            return response
        } catch {
            logger.error("[StrapiService::\(functionName)] - Failed to fetch details for post ID \(postId): \(error.localizedDescription)")
            throw error
        }
    }

    func fetchCoursesForCategory(categoryId: Int, page: Int, pageSize: Int) async throws -> StrapiListResponse<Course> {
        let functionName = #function
        logger.info("[StrapiService::\(functionName)] - Fetching courses for category ID \(categoryId), page \(page).")
        do {
            let populateQuery = "populate=icon_image,translations"
            let filterQuery = "filters[coursecategory][id][$eq]=\(categoryId)"
            let sortQuery = "sort[0]=order:asc&sort[1]=title:asc"
            guard var components = URLComponents(string: "\(Config.strapiBaseUrl)/api/courses") else { throw URLError(.badURL) }
            components.query = "\(populateQuery)&\(filterQuery)&\(sortQuery)"
            // FIX: Added explicit type annotation
            let response: StrapiListResponse<Course> = try await NetworkManager.shared.fetchPage(baseURLComponents: components, page: page, pageSize: pageSize)
            logger.info("[StrapiService::\(functionName)] - Successfully fetched \(response.data?.count ?? 0) courses for category \(categoryId).")
            return response
        } catch {
            logger.error("[StrapiService::\(functionName)] - Failed to fetch courses for category \(categoryId): \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Comment Management

    func fetchCommentsForPost(postId: Int, page: Int, pageSize: Int) async throws -> StrapiListResponse<Comment> {
        let functionName = #function
        logger.info("[StrapiService::\(functionName)] - Fetching comments for post ID \(postId), page \(page).")
        do {
            guard var components = URLComponents(string: "\(Config.strapiBaseUrl)/api/getcomments") else { throw URLError(.badURL) }
            components.queryItems = [
                URLQueryItem(name: "postId", value: String(postId)),
                URLQueryItem(name: "pagination[page]", value: String(page)),
                URLQueryItem(name: "pagination[pageSize]", value: String(pageSize))
            ]
            // FIX: Added explicit type annotation
            let response: StrapiListResponse<Comment> = try await NetworkManager.shared.fetchDirect(from: components.url!)
            logger.info("[StrapiService::\(functionName)] - Successfully fetched \(response.data?.count ?? 0) comments for post \(postId).")
            return response
        } catch {
            logger.error("[StrapiService::\(functionName)] - Failed to fetch comments for post \(postId): \(error.localizedDescription)")
            throw error
        }
    }

    func postComment(payload: CommentPostPayload) async throws -> StrapiSingleResponse<Comment> {
        let functionName = #function
        logger.info("[StrapiService::\(functionName)] - Posting new comment for post ID \(payload.data.post).")
        do {
            // FIX: Added explicit type annotation
            let response: StrapiSingleResponse<Comment> = try await NetworkManager.shared.post(to: URL(string: "\(Config.strapiBaseUrl)/api/comments")!, body: payload)
            logger.info("[StrapiService::\(functionName)] - Successfully posted comment.")
            return response
        } catch {
            logger.error("[StrapiService::\(functionName)] - Failed to post comment: \(error.localizedDescription)")
            throw error
        }
    }
}


extension StrapiService {

    /// Fetch all personality results (optionally for a given locale)
    func fetchPersonalityResults(
        locale: String? = nil,
        page: Int = 1,
        pageSize: Int = 25
    ) async throws -> StrapiListResponse<PersonalityResult> {

        let functionName = #function
        logger.info("[StrapiService::\(functionName)] - Fetching personality results. locale=\(locale ?? "nil"), page=\(page)")

        var components = URLComponents(string: "\(Config.strapiBaseUrl)/api/personality-results")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "pagination[page]", value: String(page)),
            URLQueryItem(name: "pagination[pageSize]", value: String(pageSize)),
            URLQueryItem(name: "sort", value: "createdAt:asc")
        ]
        if let locale { queryItems.append(URLQueryItem(name: "locale", value: locale)) }
        components.queryItems = queryItems

        do {
            let response: StrapiListResponse<PersonalityResult> = try await NetworkManager.shared.fetchDirect(from: components.url!)
            logger.info("[StrapiService::\(functionName)] - Received \(response.data?.count ?? 0) results.")
            return response
        } catch {
            logger.error("[StrapiService::\(functionName)] - Error: \(error.localizedDescription)")
            throw error
        }
    }

    /// Fetch a single personality result by its `ps_id` (your mapping key)
    func fetchPersonalityResult(psId: String, locale: String? = nil) async throws -> PersonalityResult? {
        let functionName = #function
        logger.info("[StrapiService::\(functionName)] - Fetching personality result by ps_id=\(psId), locale=\(locale ?? "nil")")

        var components = URLComponents(string: "\(Config.strapiBaseUrl)/api/personality-results")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "filters[ps_id][$eq]", value: psId),
            URLQueryItem(name: "pagination[page]", value: "1"),
            URLQueryItem(name: "pagination[pageSize]", value: "1")
        ]
        if let locale { queryItems.append(URLQueryItem(name: "locale", value: locale)) }
        components.queryItems = queryItems

        do {
            let response: StrapiListResponse<PersonalityResult> = try await NetworkManager.shared.fetchDirect(from: components.url!)
            let item = response.data?.first
            logger.info("[StrapiService::\(functionName)] - Found item? \(item != nil)")
            return item
        } catch {
            logger.error("[StrapiService::\(functionName)] - Error: \(error.localizedDescription)")
            throw error
        }
    }
}
