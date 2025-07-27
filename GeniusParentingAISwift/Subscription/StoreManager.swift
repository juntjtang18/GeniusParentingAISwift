// GeniusParentingAISwift/Subscription/StoreManager.swift

import Foundation
import StoreKit

enum ProductIdentifiers {
    static let basicMonthly = "ca.geniusparentingai.basic.monthly"
    static let basicYearly = "ca.geniusparentingai.basic.yearlyplan"
    static let premiumYearly = "ca.geniusparentingai.premium.yearly"
}

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    private let logger = AppLogger(category: "StoreManager")

    enum PurchaseStatus: Equatable {
        case idle, inProgress, success, failed(Error)
        var isFailed: Bool { if case .failed = self { return true }; return false }
        var errorMessage: String? { if case .failed(let error) = self { return error.localizedDescription }; return nil }
        static func == (lhs: PurchaseStatus, rhs: PurchaseStatus) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.inProgress, .inProgress), (.success, .success): return true
            case (.failed(let a), .failed(let b)): return a.localizedDescription == b.localizedDescription
            default: return false
            }
        }
    }

    @Published private(set) var products: [Product] = []
    @Published var purchaseState: PurchaseStatus = .idle
    private var transactionListener: Task<Void, Error>? = nil

    private init() {
        transactionListener = listenForTransactions()
        Task { await requestProducts() }
    }

    deinit { transactionListener?.cancel() }

    @Published private(set) var purchasedProductIDs: Set<String> = []

    func syncWithServerState(for user: StrapiUser?) {
        let functionName = #function
        guard let user = user else {
            logger.info("[\(String(describing: self))::\(functionName)] - User is nil. Clearing all local purchased product IDs.")
            self.purchasedProductIDs.removeAll()
            return
        }
        logger.info("[\(String(describing: self))::\(functionName)] - Syncing local purchases with server state for user \(user.id).")
        if let activePlanProductId = user.subscription?.data?.attributes.plan.attributes.productId {
            logger.debug("[\(String(describing: self))::\(functionName)] - Found active plan productId from server: \(activePlanProductId)")
            self.purchasedProductIDs = [activePlanProductId]
        } else {
            logger.info("[\(String(describing: self))::\(functionName)] - No active plan productId found in user's subscription. Clearing purchased IDs.")
            self.purchasedProductIDs.removeAll()
        }
        logger.info("[\(String(describing: self))::\(functionName)] - Sync complete. Final active product IDs are now: \(self.purchasedProductIDs)")
    }

    func requestProducts() async {
        let functionName = #function
        logger.info("[\(String(describing: self))::\(functionName)] - Requesting products from App Store.")
        do {
            let storeProducts = try await Product.products(for: [
                ProductIdentifiers.basicMonthly, ProductIdentifiers.basicYearly, ProductIdentifiers.premiumYearly
            ])
            self.products = storeProducts.sorted(by: { $0.price < $1.price })
            logger.info("[\(String(describing: self))::\(functionName)] - Successfully fetched \(self.products.count) products.")
        } catch {
            logger.error("[\(String(describing: self))::\(functionName)] - Failed to fetch products: \(error.localizedDescription)")
        }
    }

    func purchase(_ product: Product) async {
        let functionName = #function
        logger.info("[\(String(describing: self))::\(functionName)] - [Step 1] Starting purchase process for product: \(product.id)")
        purchaseState = .inProgress

        guard let strapiUserId = SessionManager.shared.currentUser?.id else {
            let error = NSError(domain: "StoreManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Cannot purchase because user is not logged in."])
            logger.error("[\(String(describing: self))::\(functionName)] - Purchase failed: No active Strapi user session.")
            purchaseState = .failed(error)
            return
        }
        
        logger.debug("[\(String(describing: self))::\(functionName)] - [Step 1a] Found Strapi User ID: \(strapiUserId)")

        do {
            var hexString = String(format: "%032llx", CUnsignedLongLong(strapiUserId))
            hexString.insert("-", at: hexString.index(hexString.startIndex, offsetBy: 8))
            hexString.insert("-", at: hexString.index(hexString.startIndex, offsetBy: 13))
            hexString.insert("-", at: hexString.index(hexString.startIndex, offsetBy: 18))
            hexString.insert("-", at: hexString.index(hexString.startIndex, offsetBy: 23))

            guard let appAccountToken = UUID(uuidString: hexString) else {
                let error = NSError(domain: "StoreManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not create a valid appAccountToken from the user ID."])
                logger.error("[\(String(describing: self))::\(functionName)] - Failed to generate appAccountToken for user ID \(strapiUserId) from hex string '\(hexString)'.")
                purchaseState = .failed(error)
                return
            }

            logger.debug("[\(String(describing: self))::\(functionName)] - [Step 1b] Generated appAccountToken for purchase: \(appAccountToken.uuidString)")

            let result = try await product.purchase(options: [.appAccountToken(appAccountToken)])

            switch result {
            case .success(let verification):
                logger.info("[\(String(describing: self))::\(functionName)] - [Step 2] Local purchase successful. Verifying transaction...")
                let transaction = try checkVerified(verification)
                let jws = verification.jwsRepresentation
                //logger.debug("[\(String(describing: self))::\(functionName)] - [Step 3] Transaction verified locally. JWS token obtained.")
                //logger.info("[\(String(describing: self))::\(functionName)] - [Step 4] Sending JWS and UserID to server for validation...")
                try await sendTransactionToServer(jws: jws)
                
                logger.info("[\(String(describing: self))::\(functionName)] - [Step 5] Server validation successful. Finalizing transaction.")
                await transaction.finish()
                
                purchaseState = .success
                logger.info("[\(String(describing: self))::\(functionName)] - [Step 6] Purchase process complete.")

            case .userCancelled:
                logger.info("[\(String(describing: self))::\(functionName)] - User cancelled the purchase.")
                purchaseState = .idle
            case .pending:
                logger.info("[\(String(describing: self))::\(functionName)] - Purchase is pending.")
                purchaseState = .idle
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            logger.error("[\(String(describing: self))::\(functionName)] - Purchase process failed: \(error.localizedDescription)")
            purchaseState = .failed(error)
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        let functionName = #function
        logger.info("[\(String(describing: self))::\(functionName)] - Starting transaction listener.")
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    let jws = result.jwsRepresentation
                    await MainActor.run { self.logger.info("[\(String(describing: self))::\(functionName)] - Transaction listener detected update for product: \(transaction.productID).") }
                    try await self.sendTransactionToServer(jws: jws)
                    await transaction.finish()
                } catch {
                    await MainActor.run { self.logger.error("[\(String(describing: self))::\(functionName)] - Transaction listener failed verification: \(error.localizedDescription)") }
                }
            }
        }
    }
    
    private func sendTransactionToServer(jws: String) async throws {
        let functionName = #function
        guard let user = SessionManager.shared.currentUser else {
            let error = NSError(domain: "StoreManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not logged in."])
            logger.error("[\(String(describing: self))::\(functionName)] - Could not send transaction: No active user session.")
            throw error
        }
        
        do {
            logger.debug("[\(String(describing: self))::\(functionName)] - Sending transaction JWS and UserID (\(user.id)) to backend for validation...")
            _ = try await SubscriptionService.shared.activateSubscription(receiptToken: jws, userId: user.id)
            logger.info("[\(String(describing: self))::\(functionName)] - Successfully activated subscription on server.")
            
            if let updatedUser = try? await StrapiService.shared.fetchCurrentUser() {
                SessionManager.shared.setCurrentUser(updatedUser)
                self.syncWithServerState(for: updatedUser)
                logger.debug("[\(String(describing: self))::\(functionName)] - Refreshed user data and synced server state after successful subscription.")
            }
        } catch {
            logger.error("[\(String(describing: self))::\(functionName)] - Failed to send transaction to server or process response: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        let functionName = #function
        switch result {
        case .unverified:
            logger.warning("[\(String(describing: self))::\(functionName)] - Transaction failed verification (unverified).")
            throw StoreKitError.unknown
        case .verified(let safe):
            logger.debug("[\(String(describing: self))::\(functionName)] - Transaction verification successful.")
            return safe
        }
    }
}
