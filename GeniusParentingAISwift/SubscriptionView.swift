// GeniusParentingAISwift/SubscriptionView.swift

import SwiftUI

// ADDED: Enum to rank the plans
enum PlanTier: Int, Comparable {
    case free = 0
    case basic = 1
    case premium = 2
    case unknown = -1

    init(planName: String) {
        switch planName.lowercased() {
        case "free plan": self = .free
        case "basic plan": self = .basic
        case "premium plan": self = .premium
        default: self = .unknown
        }
    }

    static func < (lhs: PlanTier, rhs: PlanTier) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

struct SubscriptionView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    @Binding var isPresented: Bool

    // ADDED: Get the current user's plan and tier
    private var currentUserPlanName: String? {
        SessionManager.shared.currentUser?.subscription?.data?.attributes.plan.attributes.name
    }
    private var currentUserPlanTier: PlanTier {
        PlanTier(planName: currentUserPlanName ?? "")
    }

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
                                let planTier = PlanTier(planName: plan.attributes.name)
                                let isCurrentUserPlan = plan.attributes.name == currentUserPlanName
                                let isDisabled = planTier < currentUserPlanTier

                                // MODIFIED: Pass state to the card view
                                SubscriptionCardView(
                                    plan: plan,
                                    isCurrentUserPlan: isCurrentUserPlan,
                                    isDisabled: isDisabled
                                )
                                .padding([.horizontal, .top])
                                .padding(.bottom, 50)
                                .frame(maxHeight: .infinity)
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
    let plan: Plan
    let isCurrentUserPlan: Bool
    let isDisabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            planInfo
            subscribeButton
            Divider()
            featuresList
            Spacer()
        }
        .padding(25)
        .background(isCurrentUserPlan || isDisabled ? Color(UIColor.systemGray6) : Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        .frame(maxWidth: 400)
        .overlay(
            isCurrentUserPlan ?
                Text("Current Plan")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .padding(.top, 10)
                : nil
            , alignment: .topTrailing
        )
        .disabled(isCurrentUserPlan || isDisabled)
        .foregroundColor(isCurrentUserPlan || isDisabled ? Color(UIColor.secondaryLabel) : .primary)
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
                .background(isCurrentUserPlan || isDisabled ? Color.gray : Color.pink)
                .cornerRadius(12)
        }
    }

    private var featuresList: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let features = plan.attributes.features.data, !features.isEmpty {
                Text("Features:")
                    .font(.headline)
                ForEach(features) { feature in
                    FeatureRow(name: feature.attributes.name, isDisabled: isCurrentUserPlan || isDisabled)
                }
            }
        }
    }
}

// MARK: - Feature Row View
private struct FeatureRow: View {
    let name: String
    let isDisabled: Bool

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(isDisabled ? .gray : .green)
            Text(name)
            Spacer()
        }
    }
}
