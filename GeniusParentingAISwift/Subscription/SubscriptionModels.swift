//
//  SubscriptionModels.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/7/25.
//

// GeniusParentingAISwift/Subscription/SubscriptionModels.swift

import Foundation

/// The payload required to activate a subscription on the backend.
struct SubscriptionActivationPayload: Codable {
    let apple_receipt: String
}

/// The expected successful response from the subscription activation endpoint.
/// This should match the structure returned by your Subscription Subsystem.
struct SubscriptionActivationResponse: Codable {
    // Note: Adjust these properties to match the actual JSON response
    // from your `/api/v1/verify-apple-purchase` endpoint.
    // For example:
    let success: Bool
    let message: String
    let subscription: ActiveSubscription?
}

struct ActiveSubscription: Codable {
    let planId: String
    let status: String
    let expiresDate: String
}
