// Models.swift

import Foundation
import SwiftUI

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
}

struct LikedPost: Codable, Identifiable {
    let id: Int
}


// MARK: - Hot Topic Models
struct Topic: Codable, Identifiable, Hashable {
    let id: Int
    let attributes: Attributes

    var title: String { attributes.title }
    var iconImageMedia: Media? { attributes.iconImage?.data }
    var content: [Content]? { attributes.content } // ADD THIS LINE

    struct Attributes: Codable, Hashable {
        let title: String
        let iconImage: StrapiRelation<Media>?
        let content: [Content]? // ADD THIS LINE

        enum CodingKeys: String, CodingKey {
            case title
            case iconImage = "icon_image"
            case content // ADD THIS LINE
        }
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
    var iconImageMedia: Media? { attributes.iconImage?.data }

    struct Attributes: Codable, Hashable {
        let text: String
        let iconImage: StrapiRelation<Media>?

        enum CodingKeys: String, CodingKey {
            case text
            case iconImage = "icon_image"
        }
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
        let providerMetadata: JSONValue?
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
        let header_image: StrapiRelation<Media>? // This field was added
    }
}

struct Course: Codable, Identifiable, Hashable {
    let id: Int
    let attributes: Attributes

    var title: String { attributes.title }
    var iconImageMedia: Media? { attributes.iconImage?.data }
    var coursecategory: CategoryData? { attributes.coursecategory?.data }
    var content: [Content]? { attributes.content }
    var translations: [String: CourseTranslation]? { attributes.translations }
    var createdAt: String? { attributes.createdAt }
    var updatedAt: String? { attributes.updatedAt }
    var publishedAt: String? { attributes.publishedAt }

    struct Attributes: Codable, Hashable {
        let title: String
        let iconImage: StrapiRelation<Media>?
        let coursecategory: StrapiRelation<CategoryData>? // Note: This should match the field name in Strapi
        let content: [Content]?
        let translations: [String: CourseTranslation]?
        let createdAt: String?
        let updatedAt: String?
        let publishedAt: String?
        let locale: String?
    }

    struct CourseTranslation: Codable, Hashable {
        let title: String
    }
}

struct Content: Codable, Identifiable, Hashable {
    let id: Int?
    let __component: String

    let data: String?
    let style: Styles?
    let imageFile: StrapiRelation<Media>?
    let videoFile: StrapiRelation<Media>?
    let externalUrl: String?
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
