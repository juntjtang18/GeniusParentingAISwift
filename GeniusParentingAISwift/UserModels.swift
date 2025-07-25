// UserModels.swift
import Foundation

// MARK: - Top-Level User Authentication Models

/// Represents the main user object returned from Strapi.
struct StrapiUser: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String
    var user_profile: UserProfile?
    // The 'role' property from the user object is the Strapi system role, which we will keep.
    let role: StrapiSystemRole?
    let subscription: StrapiRelation<Subscription>?
}

/// Represents the populated 'user_profile' relation within the StrapiUser.
struct UserProfile: Codable, Identifiable, Hashable {
    let id: Int
    let locale: String?
    let consentForEmailNotice: Bool?
    let children: [Child]?

    enum CodingKeys: String, CodingKey {
        case id, children, locale
        case consentForEmailNotice
    }
}

/// Represents the 'profile.child' component from Strapi.
struct Child: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let age: Int
    let gender: String
}


// MARK: - Role & Subscription Models

// This is the Strapi system role (e.g., 'Authenticated', 'Public').
// We rename it to avoid conflict with our new app-specific Role enum.
struct StrapiSystemRole: Codable {
    let id: Int
    let name: String
    let description: String
    let type: String
}

struct Subscription: Codable, Identifiable {
    let id: Int
    let attributes: SubscriptionAttributes
}

struct SubscriptionAttributes: Codable {
    let status: String
    let expireDate: String?
    let startDate: String?
    let plan: Plan
}

struct Sale: Codable, Hashable {
    let productId: String?
    let startDate: String?
    let endDate: String?
}

// MARK: - Plan Tier Enum
// This enum is now accessible to the entire app.
enum PlanTier: Int, Comparable {
    case free = 0
    case basic = 1
    case premium = 2
    case unknown = -1

    init(planName: String) {
        switch planName.lowercased() {
        case let name where name.contains("free"): self = .free
        case let name where name.contains("basic"): self = .basic
        case let name where name.contains("premium"): self = .premium
        default: self = .unknown
        }
    }

    static func < (lhs: PlanTier, rhs: PlanTier) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

class Plan: Codable, Identifiable, Hashable {
    let id: Int
    let attributes: PlanAttributes

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Plan, rhs: Plan) -> Bool {
        return lhs.id == rhs.id
    }
}

class PlanAttributes: Codable, Hashable {
    let name: String
    let productId: String
    let role: String? // <-- ADDED: The role string from the backend.
    let order: Int?
    let sale: Sale?
    let features: StrapiListResponse<Feature>?
    let entitlements: StrapiListResponse<Entitlement>?
    let inherit_from: StrapiRelation<Plan>?
    let childPlans: StrapiListResponse<Plan>?

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(productId)
    }
    
    static func == (lhs: PlanAttributes, rhs: PlanAttributes) -> Bool {
        return lhs.name == rhs.name && lhs.productId == rhs.productId
    }
}


struct Feature: Codable, Identifiable, Hashable {
    let id: Int
    let attributes: FeatureAttributes
}

struct FeatureAttributes: Codable, Hashable {
    let name: String
    let order: Int
}

struct Entitlement: Codable, Identifiable, Hashable {
    let id: Int
    let attributes: EntitlementAttributes
}

struct EntitlementAttributes: Codable, Hashable {
    let name: String
    let slug: String
    let isMetered: Bool?
    let limit: Int?
    let resetPeriod: String?
}
