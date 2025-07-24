// GeniusParentingAISwift/Subscription/SubscriptionView.swift

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
    let recommendedPlanTier: PlanTier?

    @State private var selectedPlanIndex: Int = 0

    // Initializer to accept the recommended plan
    init(isPresented: Binding<Bool>, recommendedPlanTier: PlanTier? = nil) {
        self._isPresented = isPresented
        self.recommendedPlanTier = recommendedPlanTier
    }
    
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
                    TabView(selection: $selectedPlanIndex) {
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
                            .tag(index)
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
                await viewModel.fetchPlans()
            }
            .task(id: viewModel.plans) {
                guard !viewModel.plans.isEmpty else { return }

                // 1. Prioritize scrolling to the recommended plan if it exists
                if let recommendedTier = recommendedPlanTier,
                   let index = viewModel.plans.firstIndex(where: { PlanTier(planName: $0.attributes.name) == recommendedTier }) {
                    selectedPlanIndex = index
                    return
                }

                // 2. Fallback to the user's current plan if no recommendation is provided
                if let userPlanName = currentUserPlanName,
                   let index = viewModel.plans.firstIndex(where: { $0.attributes.name == userPlanName }) {
                    selectedPlanIndex = index
                }
            }
        }
    }
}

// MARK: - Sparkling Badge View
private struct SparklingBadgeView: View {
    @Environment(\.theme) var theme: Theme
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.caption.bold())
                .foregroundStyle(
                    .linearGradient(
                        colors: [.yellow, .orange, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(isAnimating ? 1.2 : 0.8)
                .rotationEffect(.degrees(isAnimating ? 15 : -5))
                .shadow(color: .yellow.opacity(0.5), radius: isAnimating ? 6 : 2)

            Text("Current Plan")
                .font(.caption.bold())
                .foregroundColor(theme.text)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(theme.secondary.opacity(0.2))
        .clipShape(Capsule())
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}


// MARK: - Subscription Card View
private struct SubscriptionCardView: View {
    @Environment(\.theme) var theme: Theme
    let plan: Plan
    let isCurrentUserPlan: Bool
    let isDisabled: Bool

    /// A computed property to determine if the plan is already owned by the user.
    private var isOwned: Bool {
        isCurrentUserPlan || isDisabled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            planInfo
            subscribeButton
            Divider()
            featuresList
            Spacer()
        }
        .padding(25)
        .background(isOwned ? Color.green.opacity(0.1) : Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        .overlay(
            isCurrentUserPlan ?
                SparklingBadgeView()
                    .padding([.top, .trailing], 12)
                : nil
            , alignment: .topTrailing
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isOwned ? Color.green : Color.clear, lineWidth: 2)
        )
    }

    private var planInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(plan.attributes.name)
                .style(.subscriptionCardTitle)
                .foregroundColor(isOwned ? .secondary : .primary)
        }
    }

    private var subscribeButton: some View {
        Group {
            if !isOwned {
                Button(action: {}) {
                    Label("Subscribe now", systemImage: "arrow.right")
                        .style(.subscriptionCardButton)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.accent)
                        .cornerRadius(12)
                }
            }
        }
    }

    private var featuresList: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let featureResponse = plan.attributes.features, let features = featureResponse.data, !features.isEmpty {
                Text("Features:")
                    .style(.subscriptionCardFeatureTitle)
                    .foregroundColor(isOwned ? .secondary : .primary)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(features) { feature in
                            FeatureRow(name: feature.attributes.name, isOwned: isOwned)
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
    let isOwned: Bool

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(isOwned ? .green : theme.secondary)
            Text(name)
                .style(.subscriptionCardFeatureItem)
                .foregroundColor(isOwned ? .secondary : .primary)
            Spacer()
        }
    }
}
