// ProfileViewModel.swift
import Foundation
import KeychainAccess

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: StrapiUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let strapiUrl = "\(Config.strapiBaseUrl)/api"
    private let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")

    func fetchUserProfile() async {
        print("ProfileViewModel: Starting single-step fetchUserProfile().")
        self.isLoading = true
        self.errorMessage = nil

        guard let token = keychain["jwt"] else {
            errorMessage = "Authentication token not found."
            isLoading = false
            return
        }

        do {
            // With the backend fix, we can now make a single, direct call to the /me endpoint
            guard let url = URL(string: "\(strapiUrl)/users/me?populate[user_profile][populate]=children") else {
                throw URLError(.badURL)
            }
            print("ProfileViewModel: Fetching populated profile from \(url.absoluteString)")

            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)

            // --- DEBUGGING LINE ADDED ---
            // This will print the exact JSON response from the server to the console.
            print("ProfileViewModel: Raw JSON from /me:\n" + (String(data: data, encoding: .utf8) ?? "Unable to decode data as string"))
            // --- END DEBUGGING LINE ---

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "Bad server response: \(code)"])
            }
            
            let loadedUser = try JSONDecoder().decode(StrapiUser.self, from: data)
            print("ProfileViewModel: Successfully decoded user from /me endpoint.")
            self.user = loadedUser

        } catch {
            errorMessage = "Failed to fetch profile: \(error.localizedDescription)"
            print("ProfileViewModel: An error occurred during profile fetch: \(error)")
        }
        
        self.isLoading = false
    }
}
