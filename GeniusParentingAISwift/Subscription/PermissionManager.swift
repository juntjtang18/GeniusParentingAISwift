// GeniusParentingAISwift/Subscription/PermissionManager.swift
import Foundation
import SwiftUI
import Combine

@MainActor
// ✅ 1. PermissionManager is now an ObservableObject
final class PermissionManager: ObservableObject {
    static let shared = PermissionManager()

    var storeManager: StoreManager?

    // ✅ 2. It now publishes the current user. Views will automatically
    //       update when this property changes.
    @Published private var currentUser: StrapiUser?

    private init() {
        // Load the initial user state from the session when the app starts
        syncWithSession()
    }

    /// This function must be called whenever the user logs in, logs out,
    /// or their profile data is refreshed to keep permissions in sync.
    func syncWithSession() {
        self.currentUser = SessionManager.shared.currentUser
    }

    func canAccess(_ permission: Permission) -> Bool {
        // ✅ 3. The logic now reads from the @Published currentUser property,
        //       making it reactive for any observing SwiftUI views.
        let activeProductId = currentUser?.subscription?.data?.attributes.plan.attributes.productId

        switch permission {
        case .viewAITab, .useAIChat, .accessMembershipCourses:
            return activeProductId != nil && activeProductId != "gpa-free-plan"

        case .viewCommunityTab:
            return true

        case .canPostComment:
            return activeProductId != nil && activeProductId != "gpa-free-plan"

        case .accessPremiumCourses:
            return activeProductId == ProductIdentifiers.premiumYearly
        }
    }
}
