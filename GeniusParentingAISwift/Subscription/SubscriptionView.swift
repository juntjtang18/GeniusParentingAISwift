// GeniusParentingAISwift/Subscription/SubscriptionView.swift
import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @EnvironmentObject var storeManager: StoreManager
    @StateObject private var viewModel = SubscriptionViewModel()
    @Binding var isPresented: Bool
    
    @State private var selectedPlanIndex: Int = 0
    @State private var showSuccessAlert = false // State for success alert

    var body: some View {
        NavigationView {
            ZStack { // Use a ZStack to overlay a loading indicator
                VStack {
                    if viewModel.isLoading {
                        ProgressView("Loading Plans...")
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        TabView(selection: $selectedPlanIndex) {
                            ForEach(viewModel.displayPlans.indices, id: \.self) { index in
                                let plan = viewModel.displayPlans[index]
                                SubscriptionCardView(
                                    plan: plan,
                                    selectedPlanIndex: $selectedPlanIndex,
                                    totalPlans: viewModel.displayPlans.count
                                )
                                .padding([.horizontal, .top])
                                .padding(.bottom, 50)
                                .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                        .indexViewStyle(.page(backgroundDisplayMode: .never))
                    }
                }
                .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
                .navigationTitle("Subscription Plans")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") { isPresented = false }
                            .disabled(storeManager.purchaseState == .inProgress)
                    }
                }
                .task {
                    await viewModel.loadPlans(from: storeManager)
                }
                .onChange(of: storeManager.purchaseState) { newState in
                    if case .success = newState {
                        showSuccessAlert = true
                    }
                }
                .alert("Purchase Successful", isPresented: $showSuccessAlert) {
                    Button("OK", role: .cancel) {
                        // Dismiss the subscription view after user taps OK
                        isPresented = false
                    }
                } message: {
                    Text("Your new plan is now active!")
                }

                // Show a loading overlay when a purchase is in progress
                if case .inProgress = storeManager.purchaseState {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView("Processing...")
                        .padding()
                        .background(.white)
                        .cornerRadius(10)
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .onDisappear {
                // Reset state when the view disappears
                storeManager.purchaseState = .idle
            }
        }
    }
}

// MARK: - Subscription Card View (Restored and Updated)
private struct SubscriptionCardView: View {
    @EnvironmentObject var storeManager: StoreManager
    let plan: SubscriptionPlanViewData
    @Binding var selectedPlanIndex: Int
    let totalPlans: Int

    var isPurchased: Bool {
        storeManager.purchasedProductIDs.contains(plan.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Plan Info
            VStack(alignment: .leading, spacing: 8) {
                Text(plan.displayName)
                    .font(.title2.bold())
                Text(plan.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Subscription Controls (Arrows and Button)
            SubscriptionControlView(
                isPurchased: isPurchased,
                productToPurchase: plan.storeKitProduct,
                selectedPlanIndex: $selectedPlanIndex,
                totalPlans: totalPlans
            )

            Divider()

            // Features List from Strapi
            VStack(alignment: .leading, spacing: 16) {
                Text("Features:")
                    .font(.headline)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(plan.features) { feature in
                            FeatureRow(name: feature.attributes.name)
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(25)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        .overlay(
            isPurchased ?
                Text("Current Plan")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.2))
                    .clipShape(Capsule())
                    .padding()
                : nil
            , alignment: .topTrailing
        )
    }
}


// MARK: - Subscription Controls (Button and Arrows)
private struct SubscriptionControlView: View {
    @EnvironmentObject var storeManager: StoreManager
    let isPurchased: Bool
    let productToPurchase: Product
    @Binding var selectedPlanIndex: Int
    let totalPlans: Int

    var body: some View {
        HStack(spacing: 12) {
            arrowButton(direction: .left)

            if !isPurchased {
                subscribeButton
            } else {
                Spacer().frame(height: 50) // Placeholder
            }
            
            arrowButton(direction: .right)
        }
        .frame(maxWidth: .infinity)
    }

    private var subscribeButton: some View {
        Button(action: {
            Task {
                await storeManager.purchase(productToPurchase)
            }
        }) {
            Text("Subscribe for \(productToPurchase.displayPrice)")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
        }
        .disabled(storeManager.purchaseState == .inProgress)
    }

    private enum ArrowDirection { case left, right }
    
    @ViewBuilder
    private func arrowButton(direction: ArrowDirection) -> some View {
        Button(action: {
            withAnimation {
                if direction == .left {
                    selectedPlanIndex = max(0, selectedPlanIndex - 1)
                } else {
                    selectedPlanIndex = min(totalPlans - 1, selectedPlanIndex + 1)
                }
            }
        }) {
            Image(systemName: direction == .left ? "chevron.left.circle.fill" : "chevron.right.circle.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(.blue.opacity(0.7))
        }
        .buttonStyle(.plain)
        .opacity(isVisible(for: direction) ? 1 : 0)
        .disabled(!isVisible(for: direction))
    }

    private func isVisible(for direction: ArrowDirection) -> Bool {
        switch direction {
        case .left:
            return selectedPlanIndex > 0
        case .right:
            return selectedPlanIndex < totalPlans - 1
        }
    }
}

// MARK: - Feature Row View
private struct FeatureRow: View {
    let name: String

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(name)
                .font(.subheadline)
            Spacer()
        }
    }
}
