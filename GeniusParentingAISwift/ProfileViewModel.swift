// ProfileViewModel.swift
import Foundation

// Helper structs to decode the server response for fetching
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
    // The keychain property is no longer needed here.

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
        self.isLoading = true
        self.errorMessage = nil

        do {
            // STEP 1: Fetch the base user from /users/me using the NetworkManager
            guard let userUrl = URL(string: "\(strapiUrl)/users/me") else {
                throw URLError(.badURL)
            }
            var baseUser: StrapiUser = try await NetworkManager.shared.fetchDirect(from: userUrl)

            // STEP 2: Fetch the user profile details from /user-profiles/mine
            guard let profileUrl = URL(string: "\(strapiUrl)/user-profiles/mine") else {
                throw URLError(.badURL)
            }
            
            // This fetch is in a separate try-catch because a new user might not have a profile yet (a 404 error is expected)
            // We don't want that to prevent the base user details from loading.
            do {
                let apiResponse: UserProfileApiResponse = try await NetworkManager.shared.fetchDirect(from: profileUrl)
                let decodedData = apiResponse.data
                
                let userProfile = UserProfile(
                    id: decodedData.id,
                    consentForEmailNotice: decodedData.attributes.consentForEmailNotice,
                    children: decodedData.attributes.children
                )
                
                baseUser.user_profile = userProfile
            } catch {
                // It's normal for a new user to not have a profile, so we just log this for debugging.
                print("Could not fetch user profile details (this is expected for new users): \(error.localizedDescription)")
            }
            
            self.user = baseUser

        } catch {
            errorMessage = "Failed to fetch your main profile: \(error.localizedDescription)"
            print("ProfileViewModel: An error occurred during profile fetch: \(error)")
        }
        
        self.isLoading = false
    }

    func updateUserProfile(profileId: Int, consent: Bool, children: [EditableChild]) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            guard let profileUrl = URL(string: "\(strapiUrl)/user-profiles/mine") else {
                throw URLError(.badURL, userInfo: [NSLocalizedDescriptionKey: "Invalid URL for profile update."])
            }
            
            // Prepare the payload to send to the server
            let childrenPayload = children.map { ChildPayload(id: $0.serverId, name: $0.name, age: $0.age, gender: $0.gender) }
            let profilePayload = ProfileUpdatePayload(consentForEmailNotice: consent, children: childrenPayload)
            let wrappedPayload = RequestWrapper(data: profilePayload)
            
            // Use the generic 'put' method from the NetworkManager
            // We expect the updated profile back, so we decode it.
            let _: UserProfileApiResponse = try await NetworkManager.shared.put(to: profileUrl, body: wrappedPayload)
            
        } catch {
            errorMessage = "Failed to update profile details: \(error.localizedDescription)"
            isLoading = false
            return false
        }

        // If the update was successful, refresh the profile data to show the latest changes.
        await fetchUserProfile()
        return true
    }
}
