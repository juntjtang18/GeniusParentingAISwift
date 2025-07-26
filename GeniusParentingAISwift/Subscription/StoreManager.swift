// GeniusParentingAISwift/Subscription/StoreManager.swift
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
    // MARK: - Purchase Status Enum
    enum PurchaseStatus: Equatable {
        case idle
        case inProgress
        case success
        case failed(Error)

        // Equatable conformance to use in .onChange
        static func == (lhs: PurchaseStatus, rhs: PurchaseStatus) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.inProgress, .inProgress), (.success, .success):
                return true
            case (.failed(let a), .failed(let b)):
                return a.localizedDescription == b.localizedDescription
            default:
                return false
            }
        }
    }

    // A list of the products available for purchase.
    @Published private(set) var products: [Product] = []
    
    // The set of product IDs the user has purchased and is entitled to.
    @Published private(set) var purchasedProductIDs = Set<String>()

    // NEW: Published property for views to observe
    @Published var purchaseState: PurchaseStatus = .idle

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
    func purchase(_ product: Product) async {
        purchaseState = .inProgress
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await sendReceiptToServer(transaction: transaction)
                await updatePurchasedProducts()
                await transaction.finish()
                purchaseState = .success // Signal success
            case .userCancelled, .pending:
                purchaseState = .idle // Reset state
                break
            @unknown default:
                purchaseState = .idle // Reset state
                break
            }
        } catch {
            print("Purchase failed: \(error)")
            purchaseState = .failed(error) // Signal failure
        }
    }

    // Listens for transaction updates from the App Store.
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.sendReceiptToServer(transaction: transaction)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    private func sendReceiptToServer(transaction: Transaction) async {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
            print("StoreManager Error: Could not get App Store receipt data.")
            return
        }

        let receiptString = receiptData.base64EncodedString()

        do {
            let response = try await StrapiService.shared.activateSubscription(receipt: receiptString)
            print("StoreManager Success: Successfully activated subscription on server. Message: \(response.message)")

            if let updatedUser = try? await StrapiService.shared.fetchCurrentUser() {
                SessionManager.shared.currentUser = updatedUser
            }
        } catch {
            print("StoreManager Error: Failed to activate subscription on server. Error: \(error.localizedDescription)")
        }
    }
    
    // Checks if a transaction is cryptographically signed by Apple.
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.unknown
        case .verified(let safe):
            return safe
        }
    }
    
    // Updates the `purchasedProductIDs` set with the user's current entitlements.
    func updatePurchasedProducts() async {
        var purchasedIDs = Set<String>()
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.revocationDate == nil {
                    purchasedIDs.insert(transaction.productID)
                }
            }
        }
        self.purchasedProductIDs = purchasedIDs
    }
}
