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
            let apiAttributes = decodedData.attributes

            // 1. Manually map the personality result from the API response
            //    to the simpler InlinePersonalityResult model.
            var inlineResult: InlinePersonalityResult? = nil
            if let resultRelation = apiAttributes.personality_result, let resultData = resultRelation.data {
                let resultAttributes = resultData.attributes
                inlineResult = InlinePersonalityResult(
                    id: resultData.id,
                    title: resultAttributes.title,
                    description: resultAttributes.description,
                    powerTip: resultAttributes.powerTip,
                    psId: resultAttributes.psId
                )
            }

            // 2. Create the UserProfile object using the correct properties.
            //    The extra 'users_permissions_user' argument is now removed.
            let userProfile = UserProfile(
                id: decodedData.id,
                locale: apiAttributes.locale,
                consentForEmailNotice: apiAttributes.consentForEmailNotice,
                children: apiAttributes.children,
                personality_result: inlineResult
            )

            // 3. Update the user object and sync permissions.
            baseUser.user_profile = userProfile
            self.user = baseUser
            PermissionManager.shared.syncWithSession()
            
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
            let profileData = ProfileUpdateData(consentForEmailNotice: consent, children: childrenPayload, personality_result: nil)
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
    
    /// Unregisters the user from the server and logs them out locally.
    /// - Returns: `true` if the operation was successful, otherwise `false`.
    func unregisterUser() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Call the service to delete the user account on the server.
            try await StrapiService.shared.unregister()
            
            // 2. On success, clear the local session data.
            SessionManager.shared.logout()
            
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to delete account: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
}
