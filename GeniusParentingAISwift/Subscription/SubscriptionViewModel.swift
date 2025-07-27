// GeniusParentingAISwift/Subscription/SubscriptionViewModel.swift

import Foundation
import StoreKit

@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {}

    var displayPlans: [SubscriptionPlanViewData] {
        get {
            guard let userId = SessionManager.shared.currentUser?.id else { return [] }
            return SessionStore.shared.getUserData("subscriptionPlans", userId: userId) ?? []
        }
        set {
            if let userId = SessionManager.shared.currentUser?.id {
                SessionStore.shared.setUserData(newValue, forKey: "subscriptionPlans", userId: userId)
            }
        }
    }

    func loadPlans(from storeManager: StoreManager) async {
        isLoading = true
        errorMessage = nil

        guard let userId = SessionManager.shared.currentUser?.id else {
            errorMessage = "No active user session."
            isLoading = false
            return
        }

        do {
            // MODIFIED: Now calls the new SubscriptionService.
            let strapiPlans = try await SubscriptionService.shared.fetchPlans().data ?? []
            
            if storeManager.products.isEmpty {
                await storeManager.requestProducts()
            }
            let storeKitProducts = storeManager.products

            var mergedPlans: [SubscriptionPlanViewData] = []
            for strapiPlan in strapiPlans {
                if let matchingProduct = storeKitProducts.first(where: { $0.id == strapiPlan.attributes.productId }) {
                    mergedPlans.append(
                        SubscriptionPlanViewData(
                            id: strapiPlan.attributes.productId,
                            strapiPlan: strapiPlan,
                            storeKitProduct: matchingProduct
                        )
                    )
                }
            }
            
            SessionStore.shared.setUserData(mergedPlans.sorted(by: {
                ($0.strapiPlan.attributes.order ?? 99) < ($1.strapiPlan.attributes.order ?? 99)
            }), forKey: "subscriptionPlans", userId: userId)
            
        } catch {
            errorMessage = "Failed to load subscription plans: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
