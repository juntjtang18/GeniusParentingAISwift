import Foundation
import StoreKit

enum ProductIdentifiers {
    static let basicMonthly = "ca.geniusparentingai.basic.monthly"
    static let basicYearly = "ca.geniusparentingai.basic.yearlyplan"
    static let premiumYearly = "ca.geniusparentingai.premium.yearly"
}

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager() // Added singleton instance

    enum PurchaseStatus: Equatable {
        case idle
        case inProgress
        case success
        case failed(Error)

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

    @Published private(set) var products: [Product] = []
    @Published var purchaseState: PurchaseStatus = .idle

    private var transactionListener: Task<Void, Error>? = nil

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await requestProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    var purchasedProductIDs: Set<String> {
        get {
            guard let userId = SessionManager.shared.currentUser?.id else { return [] }
            return SessionStore.shared.getUserData("purchasedProductIDs", userId: userId) ?? []
        }
        set {
            if let userId = SessionManager.shared.currentUser?.id {
                SessionStore.shared.setUserData(newValue, forKey: "purchasedProductIDs", userId: userId)
            }
        }
    }

    func requestProducts() async {
        do {
            let storeProducts = try await Product.products(for: [
                ProductIdentifiers.basicMonthly,
                ProductIdentifiers.basicYearly,
                ProductIdentifiers.premiumYearly
            ])
            self.products = storeProducts.sorted(by: { $0.price < $1.price })
            SessionStore.shared.setNonUserData(products, forKey: "storeProducts")
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }

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
                purchaseState = .success
            case .userCancelled, .pending:
                purchaseState = .idle
                break
            @unknown default:
                purchaseState = .idle
                break
            }
        } catch {
            print("Purchase failed: \(error)")
            purchaseState = .failed(error)
        }
    }

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
        guard let userId = SessionManager.shared.currentUser?.id,
              let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
            print("StoreManager Error: Could not get App Store receipt data or user session.")
            return
        }

        let receiptString = receiptData.base64EncodedString()

        do {
            let response = try await StrapiService.shared.activateSubscription(receipt: receiptString)
            print("StoreManager Success: Successfully activated subscription on server. Message: \(response.message)")
            
            if let updatedUser = try? await StrapiService.shared.fetchCurrentUser() {
                SessionManager.shared.setCurrentUser(updatedUser)
            }
        } catch {
            print("StoreManager Error: Failed to activate subscription on server. Error: \(error.localizedDescription)")
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.unknown
        case .verified(let safe):
            return safe
        }
    }
    
    func updatePurchasedProducts() async {
        guard let userId = SessionManager.shared.currentUser?.id else { return }
        var purchasedIDs = Set<String>()
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.revocationDate == nil {
                    purchasedIDs.insert(transaction.productID)
                }
            }
        }
        SessionStore.shared.setUserData(purchasedIDs, forKey: "purchasedProductIDs", userId: userId)
    }
}
