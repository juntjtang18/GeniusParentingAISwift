import Foundation

@MainActor
class UserPreferencesManager {
    static let shared = UserPreferencesManager()
    private let userDefaults = UserDefaults.standard

    private init() {}

    private var currentUserPreferenceKey: String? {
        guard let userId = SessionManager.shared.currentUser?.id else {
            return nil
        }
        return "userPreferences_\(userId)"
    }

    func set<T>(_ value: T, forKey key: String) {
        guard let userKey = currentUserPreferenceKey else { return }
        var preferences = userDefaults.dictionary(forKey: userKey) ?? [:]
        preferences[key] = value
        userDefaults.set(preferences, forKey: userKey)
        // Also store in SessionStore for in-memory access
        if let userId = SessionManager.shared.currentUser?.id {
            SessionStore.shared.setUserData(preferences, forKey: "preferences", userId: userId)
        }
    }

    func value<T>(forKey key: String) -> T? {
        guard let userId = SessionManager.shared.currentUser?.id else { return nil }
        // Try SessionStore first for in-memory access
        if let preferences: [String: Any] = SessionStore.shared.getUserData("preferences", userId: userId) {
            return preferences[key] as? T
        }
        // Fallback to UserDefaults
        guard let userKey = currentUserPreferenceKey else { return nil }
        return userDefaults.dictionary(forKey: userKey)?[key] as? T
    }

    func clearUserPreferences() {
        guard let userKey = currentUserPreferenceKey else { return }
        print("Clearing user preferences for key: \(userKey)")
        userDefaults.removeObject(forKey: userKey)
        if let userId = SessionManager.shared.currentUser?.id {
            SessionStore.shared.setUserData([String: Any](), forKey: "preferences", userId: userId)
        }
    }
}
