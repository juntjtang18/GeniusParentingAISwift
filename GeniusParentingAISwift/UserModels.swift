// UserModels.swift
import Foundation

// NEW: Represents a user object when it's populated inside another collection type.
struct PopulatedUser: Codable, Identifiable {
    let id: Int
    let attributes: PopulatedUserAttributes
}

// NEW: Contains the actual attributes of a populated user.
struct PopulatedUserAttributes: Codable {
    let username: String
    let email: String
    var user_profile: UserProfile?
}

/// Represents the 'profile.child' component from Strapi.
struct Child: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let age: Int
    let gender: String
}

/// Represents the populated 'user_profile' object within the StrapiUser.
struct UserProfile: Codable, Identifiable, Hashable {
    let id: Int
    let consentForEmailNotice: Bool
    let children: [Child]?
}

/// Represents the main user object returned from the `/api/users/me` endpoint.
struct StrapiUser: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String
    var user_profile: UserProfile? // Changed to 'var' to allow modification after fetch
}
