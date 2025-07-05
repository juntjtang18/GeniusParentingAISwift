// StrapiAPIModels.swift

import Foundation

// MARK: - New Model for Upload Response
struct UploadResponseMedia: Codable, Identifiable {
    let id: Int
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
    let createdAt: String
    let updatedAt: String
}

// MARK: - Strapi API Response Helper Structs

struct StrapiListResponse<T: Codable>: Codable {
    let data: [T]?
    let meta: StrapiMeta?
}

struct StrapiSingleResponse<T: Codable>: Codable {
    let data: T
    let meta: StrapiMeta?
}

struct StrapiMeta: Codable {
    let pagination: StrapiPagination?
}

struct StrapiPagination: Codable {
    let page: Int
    let pageSize: Int
    let pageCount: Int
    let total: Int
}

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

// REVISED: This version now conforms to Codable and Hashable, which will fix the build errors.
struct FailableDecodable<T: Codable & Hashable>: Codable, Hashable {
    let value: T?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try? container.decode(T.self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.value)
    }
}

/// The data structure required for a login request.
struct LoginCredentials: Codable {
    let identifier: String
    let password: String
}

/// The data structure required for a registration request.
struct RegistrationPayload: Codable {
    let username: String
    let email: String
    let password: String
}

/// The data structure returned by Strapi upon successful login or registration.
struct AuthResponse: Codable {
    let jwt: String
    let user: StrapiUser
}
