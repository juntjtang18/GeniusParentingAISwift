//
//  SubscriptionPlanViewData.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/7/25.
//

// GeniusParentingAISwift/Subscription/SubscriptionPlanViewData.swift
import Foundation
import StoreKit

// This struct holds the combined, display-ready information for a single subscription plan.
struct SubscriptionPlanViewData: Identifiable {
    let id: String // The productID will serve as the unique ID
    let strapiPlan: Plan // The plan details from your Strapi backend
    let storeKitProduct: Product // The product details from the App Store

    // Convenience getters for easy access in the view
    var displayName: String { storeKitProduct.displayName }
    var description: String { storeKitProduct.description }
    var displayPrice: String { storeKitProduct.displayPrice }
    var features: [Feature] { strapiPlan.attributes.features?.data ?? [] }
}
