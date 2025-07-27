// GeniusParentingAISwift/Subscription/PermissionManager.swift
import Foundation

@MainActor
class PermissionManager {
    static let shared = PermissionManager()

    // The StoreManager is still needed to check if *any* subscription is active,
    // but the specific plan comes from the SessionManager.
    var storeManager: StoreManager?

    private init() {}

    func canAccess(_ permission: Permission) -> Bool {
        // Get the active plan's product ID directly from the session.
        let activeProductId = SessionManager.shared.currentUser?.subscription?.data?.attributes.plan.attributes.productId

        switch permission {
        case .viewAITab, .useAIChat, .accessMembershipCourses:
            // Grant access if the user has an active plan that is not the free plan.
            return activeProductId != nil && activeProductId != "gpa-free-plan"

        case .viewCommunityTab:
            return true

        case .canPostComment:
            // Grant access if the user has an active plan that is not the free plan.
            return activeProductId != nil && activeProductId != "gpa-free-plan"

        case .accessPremiumCourses:
            // Grant access only if the premium plan is the active one.
            return activeProductId == ProductIdentifiers.premiumYearly
        }
    }
}
