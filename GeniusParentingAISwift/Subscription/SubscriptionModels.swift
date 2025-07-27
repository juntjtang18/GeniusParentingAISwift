// GeniusParentingAISwift/Subscription/SubscriptionModels.swift

import Foundation

/// The payload required to activate a subscription on the backend.
struct SubscriptionActivationPayload: Codable {
    let apple_receipt: String
    let userId: Int
}

/// The expected successful response from the subscription activation endpoint.
/// MODIFIED: This now correctly matches the actual server response, which is
/// a Strapi response containing a single Subscription object.
struct SubscriptionActivationResponse: Codable {
    let data: Subscription
}

// REMOVED: The old ActiveSubscription model is no longer needed as we use the main Subscription model.
