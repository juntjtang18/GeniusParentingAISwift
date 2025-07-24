// GeniusParentingAISwift/SubscriptionViewModel.swift

import Foundation

@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var plans: [Plan] = [] // MODIFIED: Use the Plan model from UserModels.swift
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchPlans() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // MODIFIED: Use the centralized StrapiService
            let response = try await StrapiService.shared.fetchPlans()
            self.plans = response.data ?? []
            
        } catch {
            errorMessage = "Failed to fetch subscription plans: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
