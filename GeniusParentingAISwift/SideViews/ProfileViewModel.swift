// GeniusParentingAISwift/ProfileViewModel.swift

// ProfileViewModel.swift
import Foundation

// Helper structs to decode the server response for fetching
struct UserProfileAttributes: Codable {
    let locale: String?
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
    private struct UserUpdatePayload: Codable {
        let username: String
    }
    private struct RequestWrapper<T: Codable>: Codable {
        let data: T
    }

    func fetchUserProfile() async {
        self.isLoading = true
        self.errorMessage = nil

        guard var baseUser = SessionManager.shared.currentUser else {
            errorMessage = "Could not find an active user session."
            isLoading = false
            return
        }

        do {
            guard let profileUrl = URL(string: "\(strapiUrl)/user-profiles/mine") else {
                throw URLError(.badURL)
            }
            
            do {
                let apiResponse: UserProfileApiResponse = try await NetworkManager.shared.fetchDirect(from: profileUrl)
                let decodedData = apiResponse.data
                
                let userProfile = UserProfile(
                    id: decodedData.id,
                    locale: decodedData.attributes.locale,
                    consentForEmailNotice: decodedData.attributes.consentForEmailNotice,
                    children: decodedData.attributes.children
                )
                
                baseUser.user_profile = userProfile
            } catch {
                print("Could not fetch user profile details (this is expected for new users): \(error.localizedDescription)")
            }
            
            self.user = baseUser
            SessionManager.shared.currentUser = baseUser // Update session with latest profile details
        } catch {
            errorMessage = "Failed to fetch your main profile: \(error.localizedDescription)"
            print("ProfileViewModel: An error occurred during profile fetch: \(error)")
        }
        
        self.isLoading = false
    }

    func updateUserAndProfile(userId: Int, username: String, profileId: Int, consent: Bool, children: [EditableChild]) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            if username != self.user?.username && userId != 0 {
                try await updateUserAccount(userId: userId, newUsername: username)
            }
            
            try await updateUserProfileInternal(profileId: profileId, consent: consent, children: children)
            
            await fetchUserProfile()
            return true

        } catch {
            errorMessage = "Failed to save profile changes: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    private func updateUserAccount(userId: Int, newUsername: String) async throws {
        guard let url = URL(string: "\(strapiUrl)/users/\(userId)") else {
            throw URLError(.badURL, userInfo: [NSLocalizedDescriptionKey: "Invalid URL for user update."])
        }
        let payload = UserUpdatePayload(username: newUsername)
        let _: StrapiUser = try await NetworkManager.shared.put(to: url, body: payload)
    }

    private func updateUserProfileInternal(profileId: Int, consent: Bool, children: [EditableChild]) async throws {
        guard let profileUrl = URL(string: "\(strapiUrl)/user-profiles/mine") else {
            throw URLError(.badURL, userInfo: [NSLocalizedDescriptionKey: "Invalid URL for profile update."])
        }
        
        let childrenPayload = children.map { ChildPayload(id: $0.serverId, name: $0.name, age: $0.age, gender: $0.gender) }
        let profilePayload = ProfileUpdatePayload(consentForEmailNotice: consent, children: childrenPayload)
        let wrappedPayload = RequestWrapper(data: profilePayload)
        
        let _: UserProfileApiResponse = try await NetworkManager.shared.put(to: profileUrl, body: wrappedPayload)
    }
}
