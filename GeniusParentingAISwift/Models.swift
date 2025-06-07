import Foundation
import SwiftUI // For CGFloat

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
        let providerMetadata: JSONValue? // Assumes JSONValue is defined elsewhere in your project
        let createdAt: String
        let updatedAt: String
        
        private enum CodingKeys: String, CodingKey {
            case name, alternativeText, caption, width, height, formats, hash, ext, mime, size, url, provider, createdAt, updatedAt
            case previewUrl = "preview_url"
            case providerMetadata = "provider_metadata"
        }
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

// Assumes StrapiRelation is defined elsewhere or is not needed by the new models
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

// Model for Courses within a Daily Lesson
struct LessonCourse: Codable, Identifiable, Hashable {
    let id: Int
    let attributes: Course.Attributes
}

// Model for Daily Lesson Selection Component
struct DailyLessonSelection: Codable, Identifiable {
    let id: Int
    let day: String
    // Assumes StrapiListResponse is defined elsewhere in your project
    let courses: StrapiListResponse<LessonCourse>
}

// Model for the Daily Lesson Plan Single Type
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
        let name: String, description: String?, createdAt: String?, updatedAt: String?, publishedAt: String?
    }
}

struct Course: Codable, Identifiable, Hashable {
    let id: Int
    let attributes: Attributes

    var title: String { attributes.title }
    var iconImageMedia: Media? { attributes.iconImage?.data }
    var category: CategoryData? { attributes.category?.data }
    var content: [Content]? { attributes.content }
    var translations: [String: CourseTranslation]? { attributes.translations }
    var createdAt: String? { attributes.createdAt }
    var updatedAt: String? { attributes.updatedAt }
    var publishedAt: String? { attributes.publishedAt }

    struct Attributes: Codable, Hashable {
        let title: String
        let iconImage: StrapiRelation<Media>?
        let category: StrapiRelation<CategoryData>?
        let content: [Content]?
        let translations: [String: CourseTranslation]?
        let createdAt: String?
        let updatedAt: String?
        let publishedAt: String?
        
        // --- FIX: ADDED MISSING LOCALE PROPERTY ---
        let locale: String?
        
        // --- FIX: REMOVED CODINGKEYS TO ALLOW .convertFromSnakeCase TO WORK ---
        // By removing this, the decoder will automatically map the
        // JSON key "icon_image" to the Swift property "iconImage".
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
    let options: [String]?
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
