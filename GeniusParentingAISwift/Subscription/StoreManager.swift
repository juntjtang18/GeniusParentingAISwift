//
//  StoreManager.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/7/24.
//

// GeniusParentingAISwift/StoreManager.swift
import Foundation
import StoreKit

// 1. Define your product IDs in a centralized place for easy access.
//    Use the exact IDs you created in App Store Connect.
enum ProductIdentifiers {
    static let basicMonthly = "ca.geniusparentingai.basic.monthly"
    static let basicYearly = "ca.geniusparentingai.basic.yearlyplan"
    static let premiumYearly = "ca.geniusparentingai.premium.yearly"
}

@MainActor
class StoreManager: ObservableObject {
    // A list of the products available for purchase.
    @Published private(set) var products: [Product] = []
    
    // The set of product IDs the user has purchased and is entitled to.
    @Published private(set) var purchasedProductIDs = Set<String>()

    private var transactionListener: Task<Void, Error>? = nil

    init() {
        // Start a listener for transactions that happen outside the app (e.g., from a promo code).
        transactionListener = listenForTransactions()

        Task {
            // Fetch products from the App Store as soon as the manager is initialized.
            await requestProducts()
            // Update the user's purchase status.
            await updatePurchasedProducts()
        }
    }

    deinit {
        // Stop listening for transactions when the object is deallocated.
        transactionListener?.cancel()
    }

    // Fetches products from the App Store.
    func requestProducts() async {
        do {
            // Request product information using the identifiers.
            let storeProducts = try await Product.products(for: [
                ProductIdentifiers.basicMonthly,
                ProductIdentifiers.basicYearly,
                ProductIdentifiers.premiumYearly
            ])
            // Sort products by price to ensure a consistent order.
            self.products = storeProducts.sorted(by: { $0.price < $1.price })
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }

    // Initiates the purchase flow for a product.
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            // The purchase was successful, verify the transaction.
            let transaction = try checkVerified(verification)
            
            // Update the user's set of purchased products.
            await updatePurchasedProducts()

            // Always finish the transaction after unlocking the content.
            await transaction.finish()
        case .userCancelled, .pending:
            // The user cancelled or the purchase is pending (e.g., needs parental approval).
            break
        @unknown default:
            break
        }
    }

    // Listens for transaction updates from the App Store.
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Iterate over transaction updates.
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    // The transaction was successful, update the purchase status.
                    await self.updatePurchasedProducts()

                    // Always finish the transaction.
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    // Checks if a transaction is cryptographically signed by Apple.
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            // This is a suspicious transaction; do not unlock content.
            throw StoreKitError.unknown
        case .verified(let safe):
            // The transaction is valid.
            return safe
        }
    }
    
    // Updates the `purchasedProductIDs` set with the user's current entitlements.
    func updatePurchasedProducts() async {
        var purchasedIDs = Set<String>()
        // Iterate through all of the user's current entitlements.
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                // Check if the subscription is active.
                if transaction.revocationDate == nil {
                    purchasedIDs.insert(transaction.productID)
                }
            }
        }
        self.purchasedProductIDs = purchasedIDs
    }
}
