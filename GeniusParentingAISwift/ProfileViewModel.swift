// ProfileViewModel.swift
import Foundation
import KeychainAccess

// Helper structs to decode the server response
struct UserProfileAttributes: Codable {
    let consentForEmailNotice: Bool
    let children: [Child]?
}

struct UserProfileData: Codable {
    let id: Int
    let attributes: UserProfileAttributes
}

struct UserProfileApiResponse: Codable {
    let data: UserProfileData
}


@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: StrapiUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let strapiUrl = "\(Config.strapiBaseUrl)/api"
    private let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")

    // Internal helper structs for updating the profile
    private struct ChildPayload: Codable {
        let id: Int?
        let name: String
        let age: Int
        let gender: String
    }
    private struct ProfileUpdatePayload: Codable {
        let consentForEmailNotice: Bool
        let children: [ChildPayload]
    }
    private struct RequestWrapper<T: Codable>: Codable {
        let data: T
    }

    func fetchUserProfile() async {
        print("ProfileViewModel: Starting 2-step fetchUserProfile().")
        // --- FIX: This guard statement is removed to prevent a deadlock when refreshing after an update. ---
        // guard !isLoading else { return }

        self.isLoading = true
        self.errorMessage = nil

        guard let token = keychain["jwt"] else {
            errorMessage = "Authentication token not found."
            isLoading = false
            return
        }

        do {
            // STEP 1: Fetch the base user from /users/me
            guard let userUrl = URL(string: "\(strapiUrl)/users/me") else {
                throw URLError(.badURL)
            }
            var userRequest = URLRequest(url: userUrl)
            userRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (userData, _) = try await URLSession.shared.data(for: userRequest)
            var baseUser = try JSONDecoder().decode(StrapiUser.self, from: userData)

            // STEP 2: Fetch the user profile from your new /user-profiles/mine endpoint
            guard let profileUrl = URL(string: "\(strapiUrl)/user-profiles/mine") else {
                throw URLError(.badURL)
            }
            var profileRequest = URLRequest(url: profileUrl)
            profileRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (profileData, profileResponse) = try await URLSession.shared.data(for: profileRequest)
            
            if let httpProfileResponse = profileResponse as? HTTPURLResponse, httpProfileResponse.statusCode == 200 {
                
                let apiResponse = try JSONDecoder().decode(UserProfileApiResponse.self, from: profileData)
                let decodedData = apiResponse.data
                
                let userProfile = UserProfile(
                    id: decodedData.id,
                    consentForEmailNotice: decodedData.attributes.consentForEmailNotice,
                    children: decodedData.attributes.children
                )
                
                baseUser.user_profile = userProfile
                self.user = baseUser
                
            } else {
                 self.user = baseUser
            }

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
            guard let profileUrl = URL(string: "\(strapiUrl)/user-profiles/mine") else {
                throw URLError(.badURL, userInfo: [NSLocalizedDescriptionKey: "Invalid URL for profile update."])
            }
            
            var profileRequest = URLRequest(url: profileUrl)
            profileRequest.httpMethod = "PUT"
            profileRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            
            profileRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            profileRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let childrenPayload = children.map { ChildPayload(id: $0.serverId, name: $0.name, age: $0.age, gender: $0.gender) }
            let profilePayload = ProfileUpdatePayload(consentForEmailNotice: consent, children: childrenPayload)
            let wrappedPayload = RequestWrapper(data: profilePayload)
            profileRequest.httpBody = try JSONEncoder().encode(wrappedPayload)

            let (_, profileResponse) = try await URLSession.shared.data(for: profileRequest)
            
            guard let httpProfileResponse = profileResponse as? HTTPURLResponse, (200...299).contains(httpProfileResponse.statusCode) else {
                let statusCode = (profileResponse as? HTTPURLResponse)?.statusCode ?? -1
                self.errorMessage = "Failed to update profile details. Server error \(statusCode)."
                isLoading = false
                return false
            }
            
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
