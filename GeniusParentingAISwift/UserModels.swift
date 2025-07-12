// UserModels.swift
import Foundation

// MARK: - Top-Level User Authentication Models

/// Represents the main user object returned from Strapi.
struct StrapiUser: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String
    var user_profile: UserProfile?
    let role: Role?
    let subscription: StrapiRelation<Subscription>?
}

/// Represents the populated 'user_profile' relation within the StrapiUser.
struct UserProfile: Codable, Identifiable, Hashable {
    let id: Int
    let locale: String?
    let consentForEmailNotice: Bool
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

struct Role: Codable {
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

/// Represents the simplified plan object.
struct Plan: Codable, Identifiable {
    let id: Int
    let attributes: PlanAttributes
}

struct PlanAttributes: Codable {
    let name: String
    let productId: String
    let features: StrapiListResponse<Feature>
    let entitlements: StrapiListResponse<Entitlement>
}

struct Feature: Codable, Identifiable {
    let id: Int
    let attributes: FeatureAttributes
}

struct FeatureAttributes: Codable {
    let name: String
    let order: Int
}

struct Entitlement: Codable, Identifiable {
    let id: Int
    let attributes: EntitlementAttributes
}

struct EntitlementAttributes: Codable {
    let name: String
    let slug: String
    let isMetered: Bool?
    let limit: Int?
    let resetPeriod: String?
}
