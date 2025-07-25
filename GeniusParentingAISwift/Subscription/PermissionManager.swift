//
//  PermissionManager.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/07/23.
//
// GeniusParentingAISwift/Subscription/PermissionManager.swift
import Foundation

@MainActor
class PermissionManager {
    static let shared = PermissionManager()

    // Pass the StoreManager instance to the manager
    // This can be done at app launch.
    var storeManager: StoreManager?

    private init() {}

    func canAccess(_ permission: Permission) -> Bool {
        guard let purchasedIDs = storeManager?.purchasedProductIDs else {
            return false // If the store manager isn't set, deny access.
        }

        switch permission {
        case .viewAITab, .useAIChat, .accessMembershipCourses:
            // Grant access if ANY of the plans are purchased.
            return !purchasedIDs.isEmpty

        case .viewCommunityTab:
            return true

        case .canPostComment:
            // Example: Allow comments for any subscriber.
            return !purchasedIDs.isEmpty

        case .accessPremiumCourses:
            // Grant access only if the premium plan is purchased.
            return purchasedIDs.contains(ProductIdentifiers.premiumYearly)
        }
    }
}

/*
import Foundation

/// A centralized manager to handle all permission checks based on the user's role.
@MainActor
class PermissionManager {
    static let shared = PermissionManager()
    private init() {}

    /// Checks if the current user's role allows them to perform an action.
    /// - Parameter permission: The `Permission` to check.
    /// - Returns: `true` if the user has permission, otherwise `false`.
    func canAccess(_ permission: Permission) -> Bool {
        // Get the current user's role from the SessionManager.
        let userRole = SessionManager.shared.role

        // Define the access logic for each permission.
        switch permission {
        case .viewAITab, .useAIChat:
            // Access is granted if the user's role is 'basic' or higher.
            return userRole >= .basic

        case .viewCommunityTab:
            // All roles can view the community.
            return true
            
        case .canPostComment:
            // Only roles higher than 'free' can post comments.
            return userRole > .free

        case .accessPremiumCourses:
            // Only 'premium' users can access premium courses.
            return userRole == .premium
            
        case .accessMembershipCourses: // <-- ADDED
            // Users with 'basic' role or higher can access membership courses.
            return userRole >= .basic
        }
    }
    
    /// Retrieves a specific metered value (like a quota) from the user's plan entitlements.
    /// - Parameter entitlementSlug: The unique slug for the entitlement (e.g., "ai-chat-credits").
    /// - Returns: The integer value of the limit, or `nil` if not found.
    func getQuota(for entitlementSlug: String) -> Int? {
        guard let entitlements = SessionManager.shared.currentUser?.subscription?.data?.attributes.plan.attributes.entitlements?.data else {
            return nil
        }
        
        // Find the entitlement with the matching slug and return its limit.
        return entitlements.first(where: { $0.attributes.slug == entitlementSlug })?.attributes.limit
    }
}
*/
