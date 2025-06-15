import Foundation

// Represents the list response from Strapi, including pagination metadata
struct StrapiPostResponse: Codable {
    let data: [Post]
    let meta: StrapiMeta
}

// Represents a single Post object
struct Post: Codable, Identifiable, Hashable {
    let id: Int
    // MODIFIED: Changed from 'let' to 'var' to allow local modification
    var attributes: PostAttributes
    
    // Convenience properties for easier access in views
    var author: User? { attributes.authorRelation?.data }
    // MODIFIED: Made the setter available for local updates
    var likeCount: Int {
        get { attributes.likes?.data?.attributes?.count ?? 0 }
        set {
            // This allows us to manually update the count on the client-side
            let newCount = LikeCountAttributes(count: newValue)
            let newData = LikeCountData(attributes: newCount)
            attributes.likes = StrapiLikeCountResponse(data: newData)
        }
    }
    var content: String? { attributes.content }
    var creationDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: attributes.create_time ?? "")
    }
}

// Represents the 'attributes' object of a Post
struct PostAttributes: Codable, Hashable {
    let content: String?
    let create_time: String?
    
    let authorRelation: StrapiRelation<User>?
    // MODIFIED: Changed from 'let' to 'var' to allow local modification
    var likes: StrapiLikeCountResponse?
    
    enum CodingKeys: String, CodingKey {
        case content, create_time, likes
        case authorRelation = "users_permissions_user"
    }
}

// Represents the Strapi user model
struct User: Codable, Identifiable, Hashable {
    let id: Int
    let attributes: UserAttributes
    
    var username: String { attributes.username }
    var avatarUrl: String? { attributes.avatar?.data?.attributes.url }
}

struct UserAttributes: Codable, Hashable {
    let username: String
    let avatar: StrapiRelation<Media>?
}

// --- Models for Decoding the Like Count ---
struct StrapiLikeCountResponse: Codable, Hashable {
    var data: LikeCountData?
}

struct LikeCountData: Codable, Hashable {
    var attributes: LikeCountAttributes?
}

struct LikeCountAttributes: Codable, Hashable {
    var count: Int
}
