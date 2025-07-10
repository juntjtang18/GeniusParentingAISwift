import Foundation

@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var plans: [SubscriptionPlan] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchPlans() async {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(Config.subscriptionSubsystemBaseUrl)/api/v1/all-plans") else {
            errorMessage = "Invalid subscription URL."
            isLoading = false
            return
        }
        
        do {
            // MODIFIED: Replaced the URLSession call with the appropriate NetworkManager function.
            // The fetchDirect function is suitable here as the API returns the response
            // object directly without a "data" wrapper.
            let response: AllPlansResponse = try await NetworkManager.shared.fetchDirect(from: url)
            
            // The API response is already sorted by the 'order' field,
            // so no additional client-side sorting is needed.
            self.plans = response.data
            
        } catch {
            errorMessage = "Failed to fetch subscription plans: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
