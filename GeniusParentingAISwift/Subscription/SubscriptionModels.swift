// GeniusParentingAISwift/Subscription/SubscriptionModels.swift

import Foundation

/// The payload required to activate a subscription on the backend.
/// **MODIFIED:** The key is now correctly named `apple_receipt` to match the server's expectation.
struct SubscriptionActivationPayload: Codable {
    let apple_receipt: String
    let userId: Int
}

/// The expected successful response from the subscription activation endpoint.
struct SubscriptionActivationResponse: Codable {
    let success: Bool
    let message: String
    let subscription: ActiveSubscription?
}

struct ActiveSubscription: Codable {
    let planId: String
    let status: String
    let expiresDate: String
}
