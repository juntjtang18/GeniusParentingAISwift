// GeniusParentingAISwift/StrapiService.swift

import Foundation
// We no longer need to import `os` directly, as AppLogger handles it.

// These structs are used by the service, so they remain here.
struct CommentPostPayload: Codable {
    let data: CommentPostData
}
// Payload for updating only the personality_result relation
struct ProfileResultUpdatePayload: Codable {
    let data: DataBody
    struct DataBody: Codable { let personality_result: Int }
}
struct CommentPostData: Codable {
    let message: String
    let post: Int
}

struct ReadRequestPayload: Codable {
    struct DataBody: Codable {
        let unit_uuid: String
        let event_type: String?
        let dwell_ms: Int?
        let session_id: String?
        let event_id: String?
        let client_ts: String?
    }
    let data: DataBody
}

// ADD these models near the other payloads
struct PostCreatePayload: Codable {
    struct DataBody: Codable {
        let content: String
        let users_permissions_user: Int
        let media: [Int]?
    }
    let data: DataBody
}

/// A service layer for interacting with the Strapi backend API.
class StrapiService {
    
    static let shared = StrapiService()
    // Use the new AppLogger, configured for the "StrapiService" category from Logging.plist.
    private let logger = AppLogger(category: "StrapiService")

    private init() {}

    // MARK: - Authentication & User Management

    func login(credentials: LoginCredentials) async throws -> AuthResponse {
        let functionName = #function
        logger.info("[StrapiService::\(functionName)] - Attempting login for user: \(credentials.identifier)")
        do {
            let response = try await NetworkManager.shared.login(credentials: credentials)
            logger.info("[StrapiService::\(functionName)] - Login successful for user: \(response.user.username)")
            
            // ✅ REVISED: This now checks for the single 'role' object
            if let role = response.user.role {
                logger.info("[StrapiService::\(functionName)] - User role found: [\(role.name)]")
            } else {
                logger.warning("[StrapiService::\(functionName)] - User has no role assigned.")
            }

            return response
        } catch {
            logger.error("[StrapiService::\(functionName)] - Login failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func unregister() async throws {
        let functionName = #function
        logger.info("[StrapiService::\(functionName)] - Attempting to unregister and delete current user.")
        
        let url = URL(string: "\(Config.strapiBaseUrl)/api/auth/unregister")!

        do {
            // This endpoint requires a POST request but doesn't need a body.
            // We expect a simple message response, which we decode but don't need to return.
            let _: UnregisterResponse = try await NetworkManager.shared.post(to: url, body: EmptyPayload())
            
            logger.info("[StrapiService::\(functionName)] - User successfully unregistered.")
        } catch {
            logger.error("[StrapiService::\(functionName)] - Failed to unregister user: \(error.localizedDescription)")
            // Re-throw the error to be handled by the caller.
            throw error
        }
    }
    
    func fetchCurrentUser() async throws -> StrapiUser {
        let functionName = #function
        logger.info("[StrapiService::\(functionName)] - Fetching current user.")
        do {
            let user = try await NetworkManager.shared.fetchUser()
            logger.info("[StrapiService::\(functionName)] - Successfully fetched user: \(user.username)")
            
            // ✅ REVISED: Add the same logging here to verify the role during session validation
            if let role = user.role {
                logger.info("[StrapiService::\(functionName)] - User role found: [\(role.name)]")
            } else {
                logger.warning("[StrapiService::\(functionName)] - User has no role assigned.")
            }
            
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
    
    func updateUserPersonalityResult(personalityResultId: Int) async throws -> UserProfileApiResponse {
        let functionName = #function
        logger.info("[StrapiService::\(functionName)] - Updating personality_result to id \(personalityResultId).")
        let url = URL(string: "\(Config.strapiBaseUrl)/api/user-profiles/mine")!

        // Build payload with just the relation; server whitelists allowed fields
        let payload = ProfileUpdatePayload(
          data: ProfileUpdateData(consentForEmailNotice: nil, children: nil, personality_result: personalityResultId)
        )

        // If you don't want to send other fields, consider making them optional in ProfileUpdateData
        // and initializing with nil / empty to avoid overwriting server data.

        let response: UserProfileApiResponse =
            try await NetworkManager.shared.put(to: url, body: payload)
        logger.info("[StrapiService::\(functionName)] - Update success.")
        return response
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
            URLQueryItem(name: "sort", value: "createdAt:asc"),
            URLQueryItem(name: "populate[image]", value: "*") // ✅ ensure media is returned
        ]
        if let locale { queryItems.append(URLQueryItem(name: "locale", value: locale)) }
        components.queryItems = queryItems

        let response: StrapiListResponse<PersonalityResult> =
            try await NetworkManager.shared.fetchDirect(from: components.url!)
        logger.info("[StrapiService::\(functionName)] - Received \(response.data?.count ?? 0) results.")

        // ✅ Log title/ps_id and image.url for each record
        (response.data ?? []).forEach { item in
            let path = item.attributes.image?.data?.attributes.url ?? "nil"
            logger.info("[StrapiService::\(functionName)] - id=\(item.id), ps_id=\(item.attributes.psId), title='\(item.attributes.title)', image='\(path)'")
        }

        return response
    }
    
    @discardableResult
    func createPost(content: String, userId: Int, mediaIds: [Int]?) async throws -> StrapiSingleResponse<Post> {
        let functionName = #function
        let url = URL(string: "\(Config.strapiBaseUrl)/api/posts")!

        let payload = PostCreatePayload(
            data: .init(
                content: content,
                users_permissions_user: userId,
                media: (mediaIds?.isEmpty == true ? nil : mediaIds)
            )
        )

        // 🔎 Log the exact JSON payload we will send
        do {
            let enc = JSONEncoder()
            enc.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
            let data = try enc.encode(payload)
            if let json = String(data: data, encoding: .utf8) {
                logger.debug("[StrapiService::\(functionName)] - Outgoing JSON payload:\n\(json)")
            }
        } catch {
            logger.warning("[StrapiService::\(functionName)] - Failed to encode payload for logging: \(error.localizedDescription)")
        }

        logger.info("[StrapiService::\(functionName)] - Creating post for userId=\(userId), mediaCount=\(mediaIds?.count ?? 0)")

        let resp: StrapiSingleResponse<Post> = try await NetworkManager.shared.post(to: url, body: payload)

        // 🔎 Log what Strapi returned (specifically the author relation)
        let created = resp.data
        let authorId = created.attributes.users_permissions_user?.data?.id
        let authorName = created.attributes.users_permissions_user?.data?.attributes.username
        logger.info("[StrapiService::\(functionName)] - Created post id=\(created.id). authorId=\(authorId?.description ?? "nil"), username=\(authorName ?? "nil")")

        return resp
    }

    /// Fetch a single personality result by its `ps_id` (your mapping key)
    func fetchPersonalityResult(psId: String, locale: String? = nil) async throws -> PersonalityResult? {
        let functionName = #function
        logger.info("[StrapiService::\(functionName)] - Fetching personality result by ps_id=\(psId), locale=\(locale ?? "nil")")
        
        var components = URLComponents(string: "\(Config.strapiBaseUrl)/api/personality-results")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "filters[ps_id][$eq]", value: psId),
            URLQueryItem(name: "pagination[page]", value: "1"),
            URLQueryItem(name: "pagination[pageSize]", value: "1"),
            URLQueryItem(name: "populate[image]", value: "*") // ✅ ensure media is returned
        ]
        if let locale { queryItems.append(URLQueryItem(name: "locale", value: locale)) }
        components.queryItems = queryItems

        let response: StrapiListResponse<PersonalityResult> =
            try await NetworkManager.shared.fetchDirect(from: components.url!)
        let item = response.data?.first
        logger.info("[StrapiService::\(functionName)] - Found item? \(item != nil). image='\(item?.attributes.image?.data?.attributes.url ?? "nil")'")
        return item
    }
    
    func fetchPersonalityQuestions(
        locale: String? = nil,
        page: Int = 1,
        pageSize: Int = 50
    ) async throws -> StrapiListResponse<PersQuestion> {
        let functionName = #function
        logger.info("[StrapiService::\(functionName)] - Fetching personality questions. locale=\(locale ?? "nil")")

        var components = URLComponents(string: "\(Config.strapiBaseUrl)/api/pers-questions")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "sort", value: "order:asc"),
            URLQueryItem(name: "pagination[page]", value: String(page)),
            URLQueryItem(name: "pagination[pageSize]", value: String(pageSize)),
            // 👇 ensure Strapi returns the embedded component array
            URLQueryItem(name: "populate[answer]", value: "*")
            // If you want to strictly request certain fields instead of *:
            // URLQueryItem(name: "populate[answer][fields][0]", value: "code"),
            // URLQueryItem(name: "populate[answer][fields][1]", value: "text"),
        ]
        if let locale { queryItems.append(URLQueryItem(name: "locale", value: locale)) }
        components.queryItems = queryItems

        let resp: StrapiListResponse<PersQuestion> =
            try await NetworkManager.shared.fetchDirect(from: components.url!)
        logger.info("[StrapiService::\(functionName)] - Received \(resp.data?.count ?? 0) questions.")
        return resp
    }
}


// MARK: - Helpers
extension StrapiService {
    private static func throwIfNotOK(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            // Try to surface Strapi error message
            if let str = String(data: data, encoding: .utf8) {
                throw NSError(domain: "StrapiService",
                              code: http.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode): \(str)"])
            }
            throw NSError(domain: "StrapiService",
                          code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])
        }
    }
}

// MARK: - Recommendations & Read Logging
extension StrapiService {

    /// GET /api/my-recommend-course
    /// Returns: StrapiListResponse<CourseProgress>
    func fetchRecommendedCourses() async throws -> StrapiListResponse<CourseProgress> {
        let functionName = #function
        logger.info("[StrapiService::\(functionName)] - Fetching recommended courses.")
        let url = URL(string: "\(Config.strapiBaseUrl)/api/my-recommend-course")!
        let resp: StrapiListResponse<CourseProgress> = try await NetworkManager.shared.fetchDirect(from: url)
        logger.info("[StrapiService::\(functionName)] - Received \(resp.data?.count ?? 0) items.")
        return resp
    }

    /// POST /api/me/courses/:courseId/read
    /// Returns: StrapiSingleResponse<CourseProgress>
    @discardableResult
    func logCourseRead(
        courseId: Int,
        unitUUID: String,
        dwellMS: Int? = nil,
        eventType: String = "page_view",
        sessionID: String? = nil,
        eventID: String? = nil,
        clientTS: Date? = Date()
    ) async throws -> StrapiSingleResponse<CourseProgress> {
        let functionName = #function
        logger.info("[StrapiService::\(functionName)] - Log read for course \(courseId), unit \(unitUUID).")

        let isoTS = clientTS.map { ISO8601DateFormatter().string(from: $0) }
        let payload = ReadRequestPayload(
            data: .init(
                unit_uuid: unitUUID,
                event_type: eventType,
                dwell_ms: dwellMS,
                session_id: sessionID,
                event_id: eventID,
                client_ts: isoTS
            )
        )

        let url = URL(string: "\(Config.strapiBaseUrl)/api/me/courses/\(courseId)/read")!
        let result: StrapiSingleResponse<CourseProgress> =
            try await NetworkManager.shared.post(to: url, body: payload)

        logger.info("[StrapiService::\(functionName)] - Progress now \(result.data.attributes.completed_units)/\(result.data.attributes.total_units).")
        return result
    }
}
