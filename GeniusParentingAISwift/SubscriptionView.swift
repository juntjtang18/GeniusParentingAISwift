import SwiftUI

struct SubscriptionView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                // Set a background color for the entire view
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                VStack {
                    if viewModel.isLoading {
                        ProgressView("Loading Plans...")
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        // A TabView provides the horizontal, paged scrolling for plan cards.
                        TabView {
                            ForEach(viewModel.plans) { plan in
                                 ScrollView {
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
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await viewModel.fetchPlans()
            }
        }
    }
}

// MARK: - Subscription Card View
private struct SubscriptionCardView: View {
    let plan: SubscriptionPlan
    
    // Maps feature keypaths to their display-friendly names.
    private let featureDisplayNames: [PartialKeyPath<PlanFeatures>: String] = [
        \.credits: "Credits", \.exportLength: "Export length", \.standardVoices: "Standard voices",
        \.ultraRealisticVoices: "Ultra-Realistic voices", \.studioQualityVoices: "Studio-Quality voices",
        \.aiVideoClips: "AI Video clips", \.brandKits: "Brand kits", \.sceneLimits: "Scene limits",
        \.aiAvatar: "AI Avatar", \.voiceCloning: "Voice cloning", \.customVoices: "Custom voices",
        \.templates: "Templates", \.webResearch: "Web research"
    ]

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
        .frame(maxWidth: 400) // Constrain width for a better layout on larger screens
    }
    
    private var header: some View {
        // This mimics the toggle from the reference image.
        HStack(spacing: 0) {
            Text("Monthly")
                .font(.headline)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .foregroundColor(Color.blue.opacity(0.6))
                .background(Color.blue.opacity(0.2))
                .cornerRadius(20)

            Text("Yearly ⚡️50% off")
                .font(.subheadline)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .foregroundColor(.white)
                .background(Color.blue)
                .clipShape(Capsule())
                .offset(x: -15) // Overlap the views slightly
        }
    }
    
    private var planInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(plan.name)
                .font(.largeTitle.bold())
            
            Text(plan.description)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline) {
                Text("$\(Int(plan.price))")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Color.pink)
                Text("per \(plan.interval)")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var subscribeButton: some View {
        Button(action: {
            // Subscription logic will be handled here in the future.
        }) {
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
        VStack(spacing: 16) {
            ForEach(SubscriptionPlan.featureOrder, id: \.self) { keyPath in
                // Safely access feature values using their keypath
                if let value = plan.features[keyPath: keyPath] as? String {
                     FeatureRow(name: featureDisplayNames[keyPath] ?? "Unknown", value: value)
                }
            }
        }
    }
}

// MARK: - Feature Row View
private struct FeatureRow: View {
    let name: String
    let value: String

    var body: some View {
        HStack {
            Text(name)
            Image(systemName: "info.circle")
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
