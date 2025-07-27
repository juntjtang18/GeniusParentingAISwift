// GeniusParentingAISwift/SideViews/ProfileViewModel.swift
import Foundation

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    // The user object is now a direct reference to the one in SessionManager.
    // This makes the ViewModel lighter and always in sync.
    var user: StrapiUser? {
        get { SessionManager.shared.currentUser }
        set { SessionManager.shared.currentUser = newValue }
    }

    init() {}

    func fetchUserProfile() async {
        isLoading = true
        errorMessage = nil

        guard var baseUser = self.user else {
            errorMessage = "No active user session."
            isLoading = false
            return
        }

        do {
            let apiResponse = try await StrapiService.shared.fetchUserProfile()
            let decodedData = apiResponse.data
            
            let userProfile = UserProfile(
                id: decodedData.id,
                locale: decodedData.attributes.locale,
                consentForEmailNotice: decodedData.attributes.consentForEmailNotice,
                children: decodedData.attributes.children,
                users_permissions_user: nil
            )
            
            // Update the user object and assign it back to the SessionManager's property.
            baseUser.user_profile = userProfile
            self.user = baseUser
            
        } catch {
            print("Could not fetch user profile details: \(error.localizedDescription)")
            errorMessage = "Failed to fetch profile: \(error.localizedDescription)"
        }
        
        isLoading = false
    }

    func updateUserAndProfile(userId: Int, username: String, profileId: Int, consent: Bool, children: [EditableChild]) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            guard let currentUser = self.user else {
                errorMessage = "No active user session."
                isLoading = false
                return false
            }

            if username != currentUser.username && userId != 0 {
                let userPayload = UserUpdatePayload(username: username)
                _ = try await StrapiService.shared.updateUserAccount(userId: userId, payload: userPayload)
            }
            
            let childrenPayload = children.map { ChildPayload(id: $0.serverId, name: $0.name, age: $0.age, gender: $0.gender) }
            let profileData = ProfileUpdateData(consentForEmailNotice: consent, children: childrenPayload)
            let profilePayload = ProfileUpdatePayload(data: profileData)
            _ = try await StrapiService.shared.updateUserProfile(payload: profilePayload)
            
            // Re-fetch the profile to ensure the local state is perfectly in sync with the server.
            await fetchUserProfile()
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Failed to save profile changes: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
}
