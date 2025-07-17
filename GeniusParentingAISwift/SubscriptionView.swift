// GeniusParentingAISwift/SubscriptionView.swift

import SwiftUI

struct SubscriptionView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    @Binding var isPresented: Bool // MODIFIED: Changed from @Environment to @Binding

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                VStack {
                    if viewModel.isLoading {
                        ProgressView("Loading Plans...")
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        TabView {
                            ForEach(viewModel.plans) { plan in
                                 ScrollView {
                                     // MODIFIED: Pass the new Plan object
                                     SubscriptionCardView(plan: plan)
                                         .padding()
                                 }
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .automatic))
                        .indexViewStyle(.page(backgroundDisplayMode: .always))
                    }
                }
            }
            .navigationTitle("Subscription Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { isPresented = false }
                }
            }
            .task {
                await viewModel.fetchPlans()
            }
        }
    }
}

// MARK: - Subscription Card View (Refactored)
private struct SubscriptionCardView: View {
    let plan: Plan // MODIFIED: Use the Plan model

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            planInfo
            subscribeButton
            Divider()
            featuresList
        }
        .padding(25)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        .frame(maxWidth: 400)
    }
    
    private var header: some View {
        Text(plan.attributes.name)
            .font(.headline)
            .padding(.horizontal, 16).padding(.vertical, 8)
            .foregroundColor(.white)
            .background(Color.blue)
            .clipShape(Capsule())
    }
    
    private var planInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(plan.attributes.name)
                .font(.largeTitle.bold())
            
            Text("Product ID: \(plan.attributes.productId)")
                .foregroundColor(.secondary)
        }
    }
    
    private var subscribeButton: some View {
        Button(action: {}) {
            Label("Subscribe now", systemImage: "arrow.right")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.pink)
                .cornerRadius(12)
        }
    }
    
    private var featuresList: some View {
        VStack(alignment: .leading, spacing: 16) {
            // MODIFIED: Iterate through features from the new model
            if let features = plan.attributes.features.data {
                Text("Features:")
                    .font(.headline)
                ForEach(features) { feature in
                    FeatureRow(name: feature.attributes.name)
                }
            }
            
            // MODIFIED: Iterate through entitlements
            if let entitlements = plan.attributes.entitlements.data, !entitlements.isEmpty {
                Text("Entitlements:")
                    .font(.headline)
                    .padding(.top)
                ForEach(entitlements) { entitlement in
                    EntitlementRow(entitlement: entitlement.attributes)
                }
            }
        }
    }
}

// MARK: - Feature & Entitlement Row Views (Refactored)
private struct FeatureRow: View {
    let name: String

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(name)
            Spacer()
        }
    }
}

private struct EntitlementRow: View {
    let entitlement: EntitlementAttributes
    
    var body: some View {
        HStack {
            Image(systemName: "key.fill")
                .foregroundColor(.orange)
            VStack(alignment: .leading) {
                Text(entitlement.name).fontWeight(.medium)
                if entitlement.isMetered == true, let limit = entitlement.limit, let period = entitlement.resetPeriod {
                    Text("\(limit) per \(period)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
    }
}
