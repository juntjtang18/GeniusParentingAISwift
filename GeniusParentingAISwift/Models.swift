// Models.swift
import Foundation
import SwiftUI

// MARK: - User Models (for embedding in other responses)
// This definition is required by PostAttributes below.
struct PopulatedUser: Codable, Identifiable {
    let id: Int
    let attributes: PopulatedUserAttributes
}

struct PopulatedUserAttributes: Codable {
    let username: String
    let email: String?
}

// MARK: - Post Models
struct Post: Codable, Identifiable {
    let id: Int
    let attributes: PostAttributes
}

struct PostAttributes: Codable {
    let content: String
    let media: StrapiListResponse<Media>?
    let users_permissions_user: StrapiRelation<PopulatedUser>?
    let likes: LikesCount?
    let createdAt: String
    let comments: StrapiListResponse<Comment>?

    var likeCount: Int {
        likes?.data.attributes.count ?? 0
    }
}

// MARK: - Like Models
struct LikesCount: Codable {
    let data: LikesCountData
}

struct LikesCountData: Codable {
    let attributes: LikesCountAttributes
}

struct LikesCountAttributes: Codable {
    let count: Int
}

struct Like: Codable, Identifiable {
    let id: Int
    let attributes: LikeAttributes
}

struct LikeAttributes: Codable {
    let post: StrapiRelation<LikedPost>?
    let users_permissions_user: StrapiRelation<PopulatedUser>?
}

struct LikedPost: Codable, Identifiable {
    let id: Int
}


// MARK: - Hot Topic Models
struct Topic: Codable, Identifiable, Hashable {
    let id: Int
    let attributes: Attributes

    var title: String { attributes.title }
    var iconImageMedia: Media? { attributes.icon_image?.data }
    var content: [CourseContentItem]? { attributes.content }

    struct Attributes: Codable, Hashable {
        let title: String
        let icon_image: StrapiRelation<Media>?
        let content: [CourseContentItem]?
    }
}

struct HotTopic: Codable, Identifiable {
    let id: Int
    let attributes: Attributes

    struct Attributes: Codable {
        let topics: StrapiListResponse<Topic>
    }
}

// MARK: - Daily Tip Models
struct Tip: Codable, Identifiable, Hashable {
    let id: Int
    let attributes: Attributes

    var text: String { attributes.text }
    var iconImageMedia: Media? { attributes.icon_image?.data }

    struct Attributes: Codable, Hashable {
        let text: String
        let icon_image: StrapiRelation<Media>?
    }
}

struct DailyTip: Codable, Identifiable {
    let id: Int
    let attributes: Attributes

    struct Attributes: Codable {
        let tips: StrapiListResponse<Tip>
    }
}


// MARK: - Primary Data Models

struct Media: Codable, Hashable, Identifiable {
    let id: Int
    let attributes: MediaAttributes

    struct MediaAttributes: Codable, Hashable {
        let name: String
        let alternativeText: String?
        let caption: String?
        let width: Int?
        let height: Int?
        let formats: MediaFormats?
        let hash: String
        let ext: String
        let mime: String
        let size: Double
        let url: String
        let previewUrl: String?
        let provider: String
        let provider_metadata: JSONValue?
        let related: JSONValue?
        let createdAt: String
        let updatedAt: String
    }

    var urlString: String { attributes.url }
}

struct MediaFormats: Codable, Hashable {
    let thumbnail: MediaFormat?
    let large: MediaFormat?
    let medium: MediaFormat?
    let small: MediaFormat?
}

struct MediaFormat: Codable, Hashable {
    let name: String?
    let hash: String
    let ext: String
    let mime: String
    let width: Int
    let height: Int
    let size: Double
    let path: String?
    let url: String
}

struct StrapiRelation<T: Codable & Identifiable>: Codable, Hashable {
    let data: T?
    func hash(into hasher: inout Hasher) { hasher.combine(data?.id) }
    static func == (lhs: StrapiRelation<T>, rhs: StrapiRelation<T>) -> Bool {
        if lhs.data == nil && rhs.data == nil { return true }
        guard let lhsData = lhs.data, let rhsData = rhs.data else { return false }
        return lhsData.id == rhsData.id
    }
}

// MARK: - Daily Lesson Models

struct LessonCourse: Codable, Identifiable, Hashable {
    let id: Int
    let attributes: Course.Attributes
}

struct DailyLessonSelection: Codable, Identifiable {
    let id: Int
    let day: String
    let courses: StrapiListResponse<LessonCourse>
}

struct DailyLessonPlan: Codable, Identifiable {
    let id: Int
    let attributes: Attributes

    struct Attributes: Codable {
        let dailylessons: [DailyLessonSelection]
    }
}


// MARK: - Existing App Models

struct CategoryData: Codable, Identifiable, Hashable {
    let id: Int
    let attributes: CategoryAttributes

    struct CategoryAttributes: Codable, Hashable {
        let name: String
        let description: String?
        let createdAt: String?
        let updatedAt: String?
        let publishedAt: String?
        let order: Int?
        let header_image: StrapiRelation<Media>?
    }
}

struct Course: Codable, Identifiable, Hashable {
    let id: Int
    let attributes: Attributes

    var title: String { attributes.title }
    var iconImageMedia: Media? { attributes.icon_image?.data }
    var coursecategory: CategoryData? { attributes.coursecategory?.data }
    var content: [CourseContentItem]? { attributes.content }
    var translations: [String: CourseTranslation]? { attributes.translations }
    var createdAt: String? { attributes.createdAt }
    var updatedAt: String? { attributes.updatedAt }
    var publishedAt: String? { attributes.publishedAt }

    /// A computed property to determine if a course is for members only based on its category name.
    var isMembershipOnly: Bool {
        return attributes.coursecategory?.data?.attributes.name == "Membership Only"
    }

    struct Attributes: Codable, Hashable {
        let title: String
        let icon_image: StrapiRelation<Media>?
        let coursecategory: StrapiRelation<CategoryData>?
        let content: [CourseContentItem]?
        let translations: [String: CourseTranslation]?
        let createdAt: String?
        let updatedAt: String?
        let publishedAt: String?
        let locale: String?
        let order: Int?
        // The isMembershipOnly boolean field is correctly removed from here.
    }

    struct CourseTranslation: Codable, Hashable {
        let title: String
    }
}

struct CourseContentItem: Codable, Identifiable, Hashable {
    let id: Int?
    let __component: String

    let data: String?
    let style: Styles?
    let image_file: StrapiRelation<Media>?
    let video_file: StrapiRelation<Media>?
    let external_url: String?
    let videoId: String?
    let thumbnail: StrapiRelation<Media>?
    let caption: String?
    let question: String?
    let options: FailableDecodable<[String]>?
    let correctAnswer: String?
    let backbutton: Bool?
    let nextbutton: Bool?

    var uniqueIdForList: String {
        if let id = id { return "\(id)-\(__component)" }
        else { return "\(UUID().uuidString)-\(__component)" }
    }

    struct Styles: Codable, Hashable {
        let fontSize: CGFloat?, fontColor: String?, isBold: Bool?, isItalic: Bool?, textAlign: String?
    }
}

// MARK: - Comment Models
class Comment: Codable, Identifiable, Hashable {
    let id: Int
    let attributes: CommentAttributes

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Comment, rhs: Comment) -> Bool {
        return lhs.id == rhs.id
    }
}

class CommentAttributes: Codable, Hashable {
    let message: String
    let author: StrapiRelation<PopulatedUser>?
    let post: StrapiRelation<Post>?
    let parent_comment: StrapiRelation<Comment>?
    let replies: StrapiListResponse<Comment>?
    let createdAt: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(message)
        hasher.combine(createdAt)
        hasher.combine(author)
        hasher.combine(post)
        hasher.combine(parent_comment)
    }

    static func == (lhs: CommentAttributes, rhs: CommentAttributes) -> Bool {
        return lhs.message == rhs.message &&
            lhs.createdAt == rhs.createdAt &&
            lhs.author == rhs.author &&
            lhs.post == rhs.post &&
            lhs.parent_comment == rhs.parent_comment
    }
}
