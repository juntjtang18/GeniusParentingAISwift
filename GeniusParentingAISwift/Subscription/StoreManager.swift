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

    // MARK: - Published Properties
    @Published private(set) var products: [Product] = []
    @Published var purchaseState: PurchaseStatus = .idle
    
    // MARK: - Private Properties
    private var transactionListener: Task<Void, Error>? = nil

    // MARK: - Public Enum
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

    private init() {
        transactionListener = listenForTransactions()
        Task { await requestProducts() }
    }

    deinit { transactionListener?.cancel() }

    // MARK: - Public Methods
    
    func requestProducts() async {
        logger.info("Requesting products from App Store.")
        do {
            let storeProducts = try await Product.products(for: [
                ProductIdentifiers.basicMonthly, ProductIdentifiers.basicYearly, ProductIdentifiers.premiumYearly
            ])
            self.products = storeProducts.sorted(by: { $0.price < $1.price })
            logger.info("Successfully fetched \(self.products.count) products.")
        } catch {
            logger.error("Failed to fetch products: \(error.localizedDescription)")
        }
    }

    func purchase(_ product: Product) async {
        logger.info("[Step 1] Starting purchase process for product: \(product.id)")
        purchaseState = .inProgress

        // --- FINAL, CORRECT IMPLEMENTATION ---

        // 1. Get the current user's ID.
        guard let userId = SessionManager.shared.currentUser?.id else {
            logger.error("Purchase failed: User is not logged in.")
            purchaseState = .failed(NSError(domain: "StoreManager.Auth", code: -2, userInfo: [NSLocalizedDescriptionKey: "You must be logged in to make a purchase."]))
            return
        }

        // 2. Convert the integer userId to a 12-character zero-padded hex string.
        let userIdHex = String(format: "%012x", userId)
        let uuidString = "00000000-0000-0000-0000-\(userIdHex)"

        // 3. Create the final UUID object for the purchase option.
        guard let appAccountToken = UUID(uuidString: uuidString) else {
            logger.error("Could not create a valid UUID from user ID: \(userId)")
            purchaseState = .failed(NSError(domain: "StoreManager.Token", code: -3, userInfo: [NSLocalizedDescriptionKey: "Could not prepare purchase token."]))
            return
        }
        
        logger.info("Generated user-specific appAccountToken for userId \(userId): \(appAccountToken.uuidString)")
        // --- END OF IMPLEMENTATION ---
        
        do {
            // --- MODIFIED LINE ---
            // Pass the appAccountToken in the purchase options.
            let result = try await product.purchase(options: [.appAccountToken(appAccountToken)])
            // -------------------

            switch result {
            case .success(let verification):
                logger.info("[Step 2] Local purchase successful. Verifying transaction with Apple...")
                let transaction = try checkVerified(verification)
                
                logger.info("[Step 3] Verifying receipt with our server...")
                let wasSuccessful = await verifyPurchaseReceipt(jws: verification.jwsRepresentation)
                
                if wasSuccessful {
                    logger.info("[Step 4] Server verification successful. Finishing transaction.")
                    await transaction.finish()
                    purchaseState = .success
                    logger.info("[Step 5] Purchase process complete.")
                } else {
                    logger.error("[Step 4] Server verification failed. Not finishing transaction.")
                    throw NSError(domain: "StoreManager.ServerVerification", code: -1, userInfo: [NSLocalizedDescriptionKey: "Our server could not validate the purchase."])
                }

            case .userCancelled:
                logger.info("User cancelled the purchase.")
                purchaseState = .idle
            case .pending:
                logger.info("Purchase is pending.")
                purchaseState = .idle
            @unknown default:
                logger.warning("An unknown purchase result occurred.")
                purchaseState = .idle
            }
        } catch {
            logger.error("Purchase process failed: \(error.localizedDescription)")
            purchaseState = .failed(error)
        }
    }

    // MARK: - Private Methods

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await MainActor.run { self.logger.info("Transaction listener detected update for product: \(transaction.productID).") }
                    
                    if await self.verifyPurchaseReceipt(jws: result.jwsRepresentation) {
                        await transaction.finish()
                    }
                    
                } catch {
                    await MainActor.run { self.logger.error("Transaction listener failed: \(error.localizedDescription)") }
                }
            }
        }
    }
    
    private func verifyPurchaseReceipt(jws: String) async -> Bool {
        guard let user = SessionManager.shared.currentUser else {
            logger.error("Cannot verify receipt: User is not logged in.")
            return false
        }
        
        do {
            logger.debug("Sending JWS and UserID (\(user.id)) to backend for validation...")
            // The service now returns a response with the new subscription object.
            _ = try await SubscriptionService.shared.verifyPurchaseReceipt(receiptToken: jws, userId: user.id)
            
            // **CRITICAL FIX:** After the purchase is validated, fetch the *entire* user object again.
            // This guarantees that the SessionManager holds the absolute latest user state,
            // including the newly activated subscription plan.
            let updatedUser = try await StrapiService.shared.fetchCurrentUser()
            SessionManager.shared.setCurrentUser(updatedUser)
            
            logger.info("Successfully verified receipt and updated local user session with new plan.")
            return true
            
        } catch {
            logger.error("Failed to verify receipt or refresh user session: \(error.localizedDescription)")
            return false
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            logger.warning("Transaction failed verification (unverified).")
            throw StoreKitError.unknown
        case .verified(let safe):
            logger.debug("Transaction verification successful.")
            return safe
        }
    }
}
