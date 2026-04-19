// SpoonPace
// PaywallView.swift
// 订阅支付页面

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.subscriptionManager) private var subscriptionManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    @State private var selectedProduct = 0 // 0: monthly, 1: yearly
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        SVGLogoView()
                            .frame(width: 80, height: 80)
                            .foregroundColor(theme.primary)

                        Text(String(localized: "Unlock SpoonPace Pro"))
                            .font(.title)
                            .fontWeight(.bold)

                        Text(String(localized: "Get access to AI insights, unlimited tracking, and more"))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 32)

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        featureRow(icon: "wand.and.stars", text: String(localized: "AI weekly insights & pattern analysis"))
                        featureRow(icon: "text.badge.checkmark", text: String(localized: "Natural language input"))
                        featureRow(icon: "icloud", text: String(localized: "iCloud sync across devices"))
                        featureRow(icon: "chart.line.uptrend.xyaxis", text: String(localized: "Future analytics features"))
                    }
                    .padding(.horizontal)

                    // Pricing options
                    VStack(spacing: 12) {
                        if subscriptionManager.loaded {
                            if let monthly = subscriptionManager.monthlyProduct() {
                                PricingRow(
                                    title: String(localized: "Monthly"),
                                    price: monthly.displayPrice,
                                    selected: selectedProduct == 0,
                                    onTap: { selectedProduct = 0 }
                                )
                            }

                            if let yearly = subscriptionManager.yearlyProduct() {
                                PricingRow(
                                    title: String(localized: "Yearly"),
                                    price: yearly.displayPrice,
                                    subtitle: String(localized: "Best value · 2 months free"),
                                    selected: selectedProduct == 1,
                                    onTap: { selectedProduct = 1 }
                                )
                            }
                        } else {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)

                    // Subscribe button
                    Button(action: purchase) {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .controlSize(.regular)
                                    .tint(.white)
                            } else {
                                Text(String(localized: "Subscribe Now"))
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(Constants.UI.cornerRadius)
                    }
                    .disabled(isPurchasing || !subscriptionManager.loaded)
                    .padding(.horizontal)

                    // Restore
                    Button(String(localized: "Restore Purchases")) {
                        Task {
                            await subscriptionManager.checkSubscriptionStatus()
                        }
                    }
                    .foregroundColor(.secondary)

                    Text(String(localized: "Payment will be charged to your App Store account. Subscription automatically renews unless canceled at least 24 hours before the end of the current period."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .navigationTitle(String(localized: "Subscribe"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Close")) {
                        dismiss()
                    }
                }
            }
            .alert(String(localized: "Error"), isPresented: $showError) {
                Button(String(localized: "OK"), role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(theme.secondary)
                .frame(width: 24)
            Text(text)
        }
    }

    private func purchase() {
        guard subscriptionManager.loaded else { return }

        let product: Product?
        if selectedProduct == 0 {
            product = subscriptionManager.monthlyProduct()
        } else {
            product = subscriptionManager.yearlyProduct()
        }

        guard let product = product else { return }

        isPurchasing = true

        Task {
            do {
                let success = try await subscriptionManager.purchase(product)
                isPurchasing = false
                if success {
                    dismiss()
                }
            } catch {
                isPurchasing = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Pricing Row
struct PricingRow: View {
    let title: String
    let price: String
    let subtitle: String?
    let selected: Bool
    let onTap: () -> Void

    init(title: String, price: String, subtitle: String? = nil, selected: Bool, onTap: @escaping () -> Void) {
        self.title = title
        self.price = price
        self.subtitle = subtitle
        self.selected = selected
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                Spacer()
                Text(price)
                    .font(.headline)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                            .stroke(selected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Paywall Card (for insights tab)
struct PaywallCard: View {
    @Environment(\.theme) private var theme
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(theme.primary)
                    .font(.title)
                VStack(alignment: .leading) {
                    Text(String(localized: "AI Insights"))
                        .font(.headline)
                    Text(String(localized: "Subscribe to unlock personalized weekly analysis"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            Button(String(localized: "View Plans")) {
                showPaywall = true
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

#Preview {
    PaywallView()
        .withAppServices()
}
