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

    // This private struct matches the JSON payload Strapi expects for a child component.
    private struct ChildPayload: Codable {
        let id: Int?
        let name: String
        let age: Int
        let gender: String
    }
    
    // This struct matches the 'data' object for the user-profile update.
    private struct ProfileUpdatePayload: Codable {
        let consentForEmailNotice: Bool
        let children: [ChildPayload]
    }
    
    // This struct wraps the payload in a top-level "data" key.
    private struct RequestWrapper<T: Codable>: Codable {
        let data: T
    }

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
            guard let url = URL(string: "\(strapiUrl)/users/me?populate[user_profile][populate]=children") else {
                throw URLError(.badURL)
            }
            print("ProfileViewModel: Fetching populated profile from \(url.absoluteString)")

            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)

            print("ProfileViewModel: Raw JSON from /me:\n" + (String(data: data, encoding: .utf8) ?? "Unable to decode data as string"))

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

    func updateUserProfile(profileId: Int, consent: Bool, children: [EditableChild]) async -> Bool {
        print("ProfileViewModel: Starting updateUserProfile for profile ID \(profileId).")
        isLoading = true
        errorMessage = nil

        guard let token = keychain["jwt"] else {
            errorMessage = "Authentication token not found."; isLoading = false; return false
        }

        do {
            // This URL now correctly points to our new custom endpoint.
            guard let profileUrl = URL(string: "\(strapiUrl)/user-profiles/mine") else {
                throw URLError(.badURL, userInfo: [NSLocalizedDescriptionKey: "Invalid URL for profile update."])
            }
            
            var profileRequest = URLRequest(url: profileUrl)
            profileRequest.httpMethod = "PUT"
            profileRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            profileRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let childrenPayload = children.map { ChildPayload(id: $0.serverId, name: $0.name, age: $0.age, gender: $0.gender) }
            let profilePayload = ProfileUpdatePayload(consentForEmailNotice: consent, children: childrenPayload)
            let wrappedPayload = RequestWrapper(data: profilePayload)
            profileRequest.httpBody = try JSONEncoder().encode(wrappedPayload)

            print("ProfileViewModel: Updating user profile details via /mine endpoint...")
            let (profileDataResponse, profileResponse) = try await URLSession.shared.data(for: profileRequest)
            
            guard let httpProfileResponse = profileResponse as? HTTPURLResponse, (200...299).contains(httpProfileResponse.statusCode) else {
                let statusCode = (profileResponse as? HTTPURLResponse)?.statusCode ?? -1
                 if let errData = try? JSONDecoder().decode(StrapiErrorResponse.self, from: profileDataResponse) {
                     self.errorMessage = "Failed to update profile details: \(errData.error.message)"
                 } else {
                     self.errorMessage = "Failed to update profile details. Server error \(statusCode)."
                 }
                isLoading = false
                return false
            }
            print("ProfileViewModel: User profile details updated successfully.")

        } catch {
            errorMessage = "Failed to update profile details: \(error.localizedDescription)"
            isLoading = false
            return false
        }

        print("ProfileViewModel: All updates successful. Refreshing profile.")
        await fetchUserProfile()
        return true
    }
}
