// GeniusParentingAISwift/Subscription/SubscriptionViewModel.swift
import Foundation
import StoreKit

@MainActor
class SubscriptionViewModel: ObservableObject {
    // This is the final, merged list of plans that the view will display.
    @Published var displayPlans: [SubscriptionPlanViewData] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Fetches plans from both Strapi and StoreKit, then merges them.
    func loadPlans(from storeManager: StoreManager) async {
        self.isLoading = true
        self.errorMessage = nil

        do {
            // 1. Fetch plans from your Strapi backend.
            let strapiPlans = try await StrapiService.shared.fetchPlans().data ?? []
            
            // Ensure StoreKit products are loaded.
            if storeManager.products.isEmpty {
                await storeManager.requestProducts()
            }
            let storeKitProducts = storeManager.products

            // 2. Merge the two lists based on the productID.
            var mergedPlans: [SubscriptionPlanViewData] = []
            for strapiPlan in strapiPlans {
                // Find the corresponding StoreKit product.
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
            
            // 3. Sort the final list based on the 'order' field from Strapi.
            self.displayPlans = mergedPlans.sorted(by: {
                ($0.strapiPlan.attributes.order ?? 99) < ($1.strapiPlan.attributes.order ?? 99)
            })
            
        } catch {
            self.errorMessage = "Failed to load subscription plans: \(error.localizedDescription)"
        }
        
        self.isLoading = false
    }
}
