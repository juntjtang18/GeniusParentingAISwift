import Foundation
import SwiftUI

// Keep your Content, Styles, and Color extension as they are.
// They seem correctly defined for the component data.

struct Course: Codable, Identifiable {
    let id: Int
    private let attributes: Attributes // All content-related fields are nested here

    // Computed properties to access attributes easily
    var title: String { attributes.title }
    var content: [Content]? { attributes.content }
    var translations: [String: CourseTranslation]? { attributes.translations }
    // Add computed properties for any other attributes you might need, e.g., createdAt
    // var createdAt: String? { attributes.createdAt }

    // Nested struct to match Strapi's "attributes" object
    struct Attributes: Codable {
        let title: String
        let content: [Content]?
        let translations: [String: CourseTranslation]?
        // Add other attributes from your Strapi 'course' schema if they exist
        // For example, if Strapi returns createdAt, updatedAt, publishedAt:
        // let createdAt: String? // Or Date if you configure a date decoding strategy
        // let updatedAt: String?
        // let publishedAt: String?
    }

    // Your CourseTranslation struct remains the same
    struct CourseTranslation: Codable {
        let title: String
    }
}

// The Content struct and its nested Styles struct appear correct for handling dynamic zone components.
// Ensure all fields in Content and Styles match what Strapi sends for each component type.
struct Content: Codable, Identifiable, Hashable {
    let id: Int? // This 'id' is the component's own instance ID within the dynamic zone
    let __component: String
    let data: String?
    let url: String?
    let question: String?
    let options: [String]?
    let correctAnswer: String?
    let styles: Styles?

    var uniqueId: Int { self.id ?? UUID().hashValue } // Keep this if you need a non-optional ID for UI lists before component has an ID from Strapi

    struct Styles: Codable, Hashable {
        let fontSize: CGFloat?
        let fontColor: String?
        let isBold: Bool?
        let isItalic: Bool?
        let textAlign: String?
    }

    // Hashable and Equatable implementations seem fine
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(__component)
        hasher.combine(data)
        hasher.combine(url)
        hasher.combine(question)
        hasher.combine(options)
        hasher.combine(correctAnswer)
        hasher.combine(styles)
    }

    static func ==(lhs: Content, rhs: Content) -> Bool {
        return lhs.id == rhs.id &&
               lhs.__component == rhs.__component &&
               lhs.data == rhs.data &&
               lhs.url == rhs.url &&
               lhs.question == rhs.question &&
               lhs.options == rhs.options &&
               lhs.correctAnswer == rhs.correctAnswer &&
               lhs.styles == rhs.styles
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0) // Default to black if hex is invalid
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
