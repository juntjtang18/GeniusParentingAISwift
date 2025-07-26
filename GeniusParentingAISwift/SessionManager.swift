//
//  SessionManager.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/7/26.
//


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
        guard let userId = currentUser?.id,
              let subscription: StrapiRelation<Subscription> = SessionStore.shared.getUserData("subscription", userId: userId),
              let roleString = subscription.data?.attributes.plan.attributes.role else {
            return .free
        }
        return Role(rawValue: roleString) ?? .free
    }

    func isSameUser(email: String) -> Bool {
        return email.lowercased() == lastUserEmail?.lowercased()
    }

    func updateLastUserEmail(_ email: String) {
        lastUserEmail = email
    }

    func clearSession() {
        keychain["jwt"] = nil
        if let userId = currentUser?.id {
            SessionStore.shared.clearUserData(userId: userId)
        }
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
        SessionStore.shared.setUserData(user, forKey: "user", userId: user.id)
    }
}