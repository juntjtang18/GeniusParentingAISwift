// GeniusParentingAISwift/StrapiService.swift
import Foundation
import os

/// A service layer for interacting with the Strapi backend API.
class StrapiService {
    
    static let shared = StrapiService()
    private let logger = Logger(subsystem: "com.geniusparentingai.GeniusParentingAISwift", category: "StrapiService")

    private init() {}

    // MARK: - Authentication & User Management

    /// Attempts to log in the user with the provided credentials.
    /// - Parameter credentials: The user's login identifier and password.
    /// - Returns: An `AuthResponse` containing the JWT and user data.
    func login(credentials: LoginCredentials) async throws -> AuthResponse {
        logger.debug("StrapiService: Attempting login.")
        return try await NetworkManager.shared.login(credentials: credentials)
    }

    /// Fetches the profile for the currently authenticated user.
    /// - Returns: A `StrapiUser` object.
    func fetchCurrentUser() async throws -> StrapiUser {
        logger.debug("StrapiService: Fetching current user profile.")
        return try await NetworkManager.shared.fetchUser()
    }
}
