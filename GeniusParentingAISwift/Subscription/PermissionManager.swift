// GeniusParentingAISwift/Subscription/PermissionManager.swift
import Foundation
import SwiftUI
import Combine

@MainActor
final class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    @Published private var currentUser: StrapiUser?

    /// A computed set of all entitlement slugs the current user has.
    private var userEntitlementSlugs: Set<String> {
        guard let entitlements = currentUser?.subscription?.data?.attributes.plan.attributes.entitlements?.data else {
            return []
        }
        // Use compactMap to safely unwrap the attributes and get the slug for each entitlement.
        return Set(entitlements.compactMap { $0.attributes.slug })
    }

    private init() {
        syncWithSession()
    }

    func syncWithSession() {
        self.currentUser = SessionManager.shared.currentUser
    }

    /// Checks if the user has a specific permission by looking for a matching entitlement slug.
    func canAccess(_ permission: Permission) -> Bool {
        // The logic is now a simple, direct check.
        return userEntitlementSlugs.contains(permission.slug)
    }
}
