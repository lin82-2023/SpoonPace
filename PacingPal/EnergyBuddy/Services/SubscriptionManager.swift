// PacingPal
// SubscriptionManager.swift
// StoreKit 2 订阅管理

import Foundation
import StoreKit
import SwiftUI

@MainActor
@Observable
final class SubscriptionManager {
    nonisolated static let shared: SubscriptionManager = MainActor.assumeIsolated {
        SubscriptionManager()
    }

    private(set) var isSubscribed = false
    private(set) var products: [Product] = []
    private(set) var loaded = false

    private var updateListener: Task<Void, Never>?

    init() {
        updateListener = Task { @MainActor in
            await self.listenForTransactionUpdates()
        }
    }

    func loadProducts() async {
        do {
            let ids: Set<String> = [
                Constants.Subscription.monthlyProductID,
                Constants.Subscription.yearlyProductID
            ]
            products = try await Product.products(for: ids)
            products.sort { $0.price < $1.price }
            loaded = true
            await checkSubscriptionStatus()
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await checkSubscriptionStatus()
            await transaction.finish()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    func checkSubscriptionStatus() async {
        isSubscribed = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productID == Constants.Subscription.monthlyProductID ||
                   transaction.productID == Constants.Subscription.yearlyProductID {
                    isSubscribed = true
                    break
                }
            } catch {
                continue
            }
        }
    }

    private func listenForTransactionUpdates() async {
        for await update in Transaction.updates {
            do {
                let transaction = try checkVerified(update)
                await checkSubscriptionStatus()
                await transaction.finish()
            } catch {
                continue
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.unverifiedTransaction
        case .verified(let safe):
            return safe
        }
    }

    func monthlyProduct() -> Product? {
        products.first { $0.id == Constants.Subscription.monthlyProductID }
    }

    func yearlyProduct() -> Product? {
        products.first { $0.id == Constants.Subscription.yearlyProductID }
    }
}

enum SubscriptionError: Error {
    case unverifiedTransaction
}

extension EnvironmentValues {
    @Entry var subscriptionManager: SubscriptionManager = .shared
}
