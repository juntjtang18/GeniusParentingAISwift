// GeniusParentingAISwift/Subscription/SubscriptionService.swift

import Foundation

/// A dedicated service for handling all subscription-related network calls.
class SubscriptionService {
    static let shared = SubscriptionService()
    private let logger = AppLogger(category: "SubscriptionService")

    private init() {}

    /// Fetches the available subscription plans from the main Strapi server.
    func fetchPlans() async throws -> StrapiListResponse<Plan> {
        let functionName = #function
        logger.info("[\(String(describing: self))::\(functionName)] - Fetching subscription plans.")
        do {
            guard let url = URL(string: "\(Config.strapiBaseUrl)/api/plans?populate=deep") else {
                throw URLError(.badURL)
            }
            let response: StrapiListResponse<Plan> = try await NetworkManager.shared.fetchDirect(from: url)
            logger.info("[\(String(describing: self))::\(functionName)] - Successfully fetched \(response.data?.count ?? 0) plans.")
            return response
        } catch {
            logger.error("[\(String(describing: self))::\(functionName)] - Failed to fetch plans: \(error.localizedDescription)")
            throw error
        }
    }

    /// Verifies a purchase receipt with the backend. The backend validates it with Apple and updates the user's subscription.
    /// RENAMED: from activateSubscription to verifyPurchaseReceipt
    func verifyPurchaseReceipt(receiptToken: String, userId: Int) async throws -> SubscriptionActivationResponse {
        let functionName = #function
        logger.info("[\(String(describing: self))::\(functionName)] - Verifying purchase receipt for userId: \(userId).")
        do {
            let payload = SubscriptionActivationPayload(apple_receipt: receiptToken, userId: userId)
            guard let url = URL(string: "\(Config.strapiBaseUrl)/api/v1/subscriptions/activate") else {
                throw URLError(.badURL)
            }
            let response: SubscriptionActivationResponse = try await NetworkManager.shared.post(to: url, body: payload)
            logger.info("[\(String(describing: self))::\(functionName)] - Receipt verification request sent successfully.")
            return response
        } catch {
            logger.error("[\(String(describing: self))::\(functionName)] - Failed to verify receipt: \(error.localizedDescription)")
            throw error
        }
    }
}
