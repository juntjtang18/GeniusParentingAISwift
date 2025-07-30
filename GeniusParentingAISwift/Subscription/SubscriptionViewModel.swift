// GeniusParentingAISwift/Subscription/SubscriptionViewModel.swift

import Foundation
import StoreKit

@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var displayPlans: [SubscriptionPlanViewData] = []
    @Published var initialPlanIndex: Int = 0

    init() {}

    func loadPlans(from storeManager: StoreManager) async {
        isLoading = true
        errorMessage = nil

        // We still check for a user session, as loading plans might be a protected action.
        guard let currentUser = SessionManager.shared.currentUser else {
            errorMessage = "No active user session."
            isLoading = false
            return
        }

        do {
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
            
            // The data is now stored directly in the @Published property.
            self.displayPlans = mergedPlans.sorted(by: {
                ($0.strapiPlan.attributes.order ?? 99) < ($1.strapiPlan.attributes.order ?? 99)
            })

            // Find the index of the user's current plan
            if let currentProductId = currentUser.subscription?.data?.attributes.plan.attributes.productId {
                if let index = self.displayPlans.firstIndex(where: { $0.id == currentProductId }) {
                    self.initialPlanIndex = index
                }
            }
            
        } catch {
            errorMessage = "Failed to load subscription plans: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
