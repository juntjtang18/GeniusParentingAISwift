// GeniusParentingAISwift/SessionManager.swift

import Foundation
import KeychainAccess

@MainActor
class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published var currentUser: StrapiUser?
    private var lastUserEmail: String?
    private let keychain = Keychain(service: Config.keychainService)

    private init() {}

    var role: Role {
        guard let subscription = currentUser?.subscription,
              let roleString = subscription.data?.attributes.plan.attributes.role else {
            return .free
        }
        return Role(rawValue: roleString) ?? .free
    }
    
    // MARK: - Core Session Logic
    
    /// Establishes a new session after a successful login.
    func startSession(jwt: String, user: StrapiUser) {
        setJWT(jwt)
        setCurrentUser(user)
        updateLastUserEmail(user.email)
        PermissionManager.shared.syncWithSession()
    }
    
    /// The central function for logging out the user.
    func logout() {
        clearSession()
        PermissionManager.shared.syncWithSession()
        // Post a notification so the root view can react and update the UI.
        NotificationCenter.default.post(name: .didLogout, object: nil)
    }

    func refreshCurrentUserFromServer() async {
        let logger = AppLogger(category: "SessionManager")
        logger.info("Attempting to refresh current user session from server.")
        do {
            let updatedUser = try await StrapiService.shared.fetchCurrentUser()
            self.currentUser = updatedUser
            logger.info("Successfully refreshed and updated current user: \(updatedUser.username)")
        } catch {
            logger.error("Failed to refresh current user from server: \(error.localizedDescription)")
            // Decide if you want to clear the session on a failed refresh.
            // For now, we will leave the stale data.
        }
    }
    
    // MARK: - Helpers
    
    func isSameUser(email: String) -> Bool {
        return email.lowercased() == lastUserEmail?.lowercased()
    }

    func updateLastUserEmail(_ email: String) {
        lastUserEmail = email
    }

    func clearSession() {
        keychain["jwt"] = nil
        currentUser = nil
        lastUserEmail = nil
    }

    func getJWT() -> String? {
        return keychain["jwt"]
    }

    func setJWT(_ jwt: String) {
        keychain["jwt"] = jwt
    }

    func setCurrentUser(_ user: StrapiUser) {
        currentUser = user
    }
}
