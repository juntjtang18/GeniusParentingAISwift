// StrapiAPIModels.swift

import Foundation

// MARK: - Strapi API Response Helper Structs

// Generic Strapi response structure for a list of items
struct StrapiListResponse<T: Codable>: Codable {
    let data: [T]? // FIX: Made optional to handle cases where the data key is null
    let meta: StrapiMeta?
}

// Strapi response for a single item
struct StrapiSingleResponse<T: Codable>: Codable {
    let data: T
    let meta: StrapiMeta?
}

// Strapi's typical metadata structure (for pagination, etc.)
struct StrapiMeta: Codable {
    let pagination: StrapiPagination?
}

struct StrapiPagination: Codable {
    let page: Int
    let pageSize: Int
    let pageCount: Int
    let total: Int
}

// Strapi's typical error response structure
struct StrapiErrorResponse: Codable {
    let data: JSONValue?
    let error: StrapiError
}

struct StrapiError: Codable {
    let status: Int
    let name: String
    let message: String
    let details: JSONValue?
}

// Helper to decode flexible JSONValue for error details or other dynamic parts
// From: https://stackoverflow.com/a/48233135/4898050
public enum JSONValue: Codable, Hashable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if container.decodeNil() {
            self = .null
        }
        else {
            throw DecodingError.typeMismatch(JSONValue.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Unsupported JSON type"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}
