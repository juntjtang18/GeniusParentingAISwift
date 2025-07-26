//
//  SessionStore.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/7/26.
//


import Foundation

@MainActor
class SessionStore {
    static let shared = SessionStore()

    private var userData: [Int: [String: Any]] = [:] // Keyed by user ID
    private var nonUserData: [String: Any] = [:] // App-wide data

    private init() {}

    /// Stores user-specific data for the given user ID.
    func setUserData<T>(_ value: T, forKey key: String, userId: Int) {
        if userData[userId] == nil {
            userData[userId] = [:]
        }
        userData[userId]?[key] = value
    }

    /// Retrieves user-specific data for the given user ID.
    func getUserData<T>(_ key: String, userId: Int) -> T? {
        return userData[userId]?[key] as? T
    }

    /// Clears all data for a specific user.
    func clearUserData(userId: Int) {
        userData[userId] = nil
    }

    /// Clears all user-specific data (e.g., on logout or new user login).
    func clearAllUserData() {
        userData.removeAll()
    }

    /// Stores non-user-specific data.
    func setNonUserData<T>(_ value: T, forKey key: String) {
        nonUserData[key] = value
    }

    /// Retrieves non-user-specific data.
    func getNonUserData<T>(_ key: String) -> T? {
        return nonUserData[key] as? T
    }
}