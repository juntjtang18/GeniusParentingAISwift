// GeniusParentingAISwift/SubscriptionView.swift

import SwiftUI

enum PlanTier: Int, Comparable {
    case free = 0
    case basic = 1
    case premium = 2
    case unknown = -1

    init(planName: String) {
        switch planName.lowercased() {
        case let name where name.contains("free"): self = .free
        case let name where name.contains("basic"): self = .basic
        case let name where name.contains("premium"): self = .premium
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
    
    // ADDED: State to control the currently displayed page in the TabView.
    @State private var selectedPlanIndex: Int = 0

    private var currentUserPlanName: String? {
        SessionManager.shared.currentUser?.subscription?.data?.attributes.plan.attributes.name
    }
    private var currentUserPlanTier: PlanTier {
        PlanTier(planName: currentUserPlanName ?? "")
    }

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading Plans...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    // MODIFIED: The TabView's selection is now bound to the state variable.
                    TabView(selection: $selectedPlanIndex) {
                        // MODIFIED: Iterate over indices to tag each page view.
                        ForEach(viewModel.plans.indices, id: \.self) { index in
                            let plan = viewModel.plans[index]
                            let planTier = PlanTier(planName: plan.attributes.name)
                            let isCurrentUserPlan = plan.attributes.name == currentUserPlanName
                            let isDisabled = planTier < currentUserPlanTier

                            SubscriptionCardView(
                                plan: plan,
                                isCurrentUserPlan: isCurrentUserPlan,
                                isDisabled: isDisabled
                            )
                            .padding([.horizontal, .top])
                            .padding(.bottom, 50)
                            .frame(maxHeight: .infinity)
                            .tag(index) // Tag the view with its corresponding index.
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                }
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Subscription Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { isPresented = false }
                }
            }
            .task {
                // This task still fetches the plans as before.
                await viewModel.fetchPlans()
            }
            // ADDED: This new task runs whenever viewModel.plans changes.
            .task(id: viewModel.plans) {
                // We run this check only after the plans have been loaded.
                guard !viewModel.plans.isEmpty, let userPlanName = currentUserPlanName else { return }

                // Find the index of the user's current plan.
                if let index = viewModel.plans.firstIndex(where: { $0.attributes.name == userPlanName }) {
                    // Update the state variable to scroll the TabView to the correct page.
                    selectedPlanIndex = index
                }
            }
        }
    }
}

// MARK: - Subscription Card View (The rest of the file remains unchanged)
private struct SubscriptionCardView: View {
    @Environment(\.theme) var theme: Theme
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
        .subscriptionCardStyle(isHighlighted: isCurrentUserPlan || isDisabled)
        .frame(maxWidth: 400)
        .overlay(
            isCurrentUserPlan ?
                Text("Current Plan")
                    .style(.subscriptionPlanBadge)
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
                .style(.subscriptionCardTitle)
        }
    }

    private var subscribeButton: some View {
        Button(action: {}) {
            Label("Subscribe now", systemImage: "arrow.right")
                .style(.subscriptionCardButton)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isCurrentUserPlan || isDisabled ? Color.gray : theme.accent)
                .cornerRadius(12)
        }
    }

    private var featuresList: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let featureResponse = plan.attributes.features, let features = featureResponse.data, !features.isEmpty {
                Text("Features:")
                    .style(.subscriptionCardFeatureTitle)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(features) { feature in
                            FeatureRow(name: feature.attributes.name, isDisabled: isCurrentUserPlan || isDisabled)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Feature Row View
private struct FeatureRow: View {
    @Environment(\.theme) var theme: Theme
    let name: String
    let isDisabled: Bool

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(isDisabled ? .gray : theme.secondary)
            Text(name)
                .style(.subscriptionCardFeatureItem)
            Spacer()
        }
    }
}
